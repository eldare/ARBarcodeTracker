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
    private var cycleCounter = 0
    private let processOnceEveryNumberOfCycles = 20
    private var isReadyToProcess = false {
        didSet {
            print(isReadyToProcess ? "ready to start processing" : "waiting to start processing")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDebug()
        setupScene()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupAndStartARSession()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupAndStartCoachingOverlay()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        puaseARSession()
    }
}

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
        configuration.planeDetection = [.vertical]  // TODO: incomplete - *ELDAR* - explain assumption for vertical only
        sceneView.session.run(configuration)
    }

    private func puaseARSession() {  // TODO: incomplete - *ELDAR* - is the start after pause written correctly?
        sceneView.session.pause()
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard isReadyToProcess else { return }
        guard cycleCounter >= processOnceEveryNumberOfCycles else {
            cycleCounter += 1
            return
        }
        cycleCounter = 0
        viewModel.process(arFrame: frame)
    }
}

extension ViewController: ViewProtocol {
    func addNode(_ node: SCNNode) {
        sceneView.scene.rootNode.addChildNode(node)
    }
}

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
        coachingOverlay.goal = .verticalPlane
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        print("Info: coaching finished")
        isReadyToProcess = true
    }
}
