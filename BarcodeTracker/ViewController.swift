//
//  ViewController.swift
//  BarcodeTracker
//
//  Created by Eldar Eliav on 07/08/2020.
//  Copyright © 2020 none. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

protocol ViewProtocol: class {
    func addNode(_ node: SCNNode)
}

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!

    lazy private var viewModel: ViewModelProtocol = {
        return ViewModel(delegate: self)
    }()

    // helps keep the performance by allowing processing once every X number of cycles through ARKit delegate
    private let processOnceEveryNumberOfCycles = 20
    private var cycleCounter = 0

    // vertical configuration only, to track on a wall
    private let arSessionPlaneDetection: ARWorldTrackingConfiguration.PlaneDetection = [.vertical]
    private let coachingGoal: ARCoachingOverlayView.Goal = .verticalPlane

    // indicates when we can start processing AR frames, to find barcodes and track them
    private var isReadyToProcess = false {
        didSet {
            print(isReadyToProcess ? "ready to start processing" : "waiting to start processing")
        }
    }

    // MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // 1.
        // setup scene we're going to place nodes on
        setupScene()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 2.
        // Configure AR session and run it;
        // We are not yet ready for processing
        setupAndStartARSession()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 3.
        // Setup and start coaching overlay;
        // This will require the user to move the device to provide better result.
        // Coaching goal is vertical planes, like a wall.
        setupAndStartCoachingOverlay()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        puaseARSession()
    }
}

// MARK: - private meta
extension ViewController {
    private func setupDebug() {
        sceneView.debugOptions = [
            .showFeaturePoints,
            .showWireframe,
            .showWorldOrigin,
        ]
    }

    private func setupScene() {
        sceneView.session.delegate = self
        sceneView.scene = SCNScene()
    }

    private func setupAndStartARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = arSessionPlaneDetection
        sceneView.session.run(configuration)
    }

    private func puaseARSession() {
        sceneView.session.pause()
    }
}

// MARK: - ARSessionDelegate related
extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // 5.
        // Process incoming AR frames.
        // Vision is quite heavy on resources, so processing will only be called
        // once for X number of cycles (this method is called).
        guard isReadyToProcess else { return }
        guard cycleCounter >= processOnceEveryNumberOfCycles else {
            cycleCounter += 1
            return
        }
        cycleCounter = 0
        viewModel.process(arFrame: frame)
    }
}

// MARK: - ViewProtocol related
extension ViewController: ViewProtocol {
    func addNode(_ node: SCNNode) {
        // 15.
        // A new node is placed on our SceneView, to indicate where the detect barcode is.
        //
        // FIN.
        sceneView.scene.rootNode.addChildNode(node)
    }
}

// MARK: - ARCoachingOverlayViewDelegate related
extension ViewController: ARCoachingOverlayViewDelegate {
    private func setupAndStartCoachingOverlay() {
        let coachingOverlay = ARCoachingOverlayView()

        coachingOverlay.session = sceneView.session
        coachingOverlay.delegate = self

        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(coachingOverlay)

        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])

        coachingOverlay.activatesAutomatically = true
        coachingOverlay.goal = coachingGoal
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        // 4.
        // Coaching overlay was dismissed;
        // Meaning ARKit has enough data for us to start processing.
        // The next AR session didUpdate delegate call will start processing.
        print("Info: coaching finished")
        isReadyToProcess = true
    }
}
