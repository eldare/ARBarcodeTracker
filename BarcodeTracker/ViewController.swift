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

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!

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

extension ViewController {
    private func startBarcodeDetection() {
        // TODO: incomplete - *ELDAR* -
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
        startBarcodeDetection()
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // TODO: incomplete - *ELDAR* -
    }
}
