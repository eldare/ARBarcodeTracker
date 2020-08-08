//
//  ViewModel.swift
//  BarcodeTracker
//
//  Created by Eldar Eliav on 08/08/2020.
//  Copyright © 2020 none. All rights reserved.
//

import Foundation
import ARKit

protocol ViewModelProtocol {
    func process(arFrame: ARFrame)
}

class ViewModel {

    unowned let viewDelegate: ViewProtocol

    lazy private var detector: BarcodeDetector = {
        return BarcodeDetector(searchCompletion: self.searchCompleted)
    }()

    private var knownBarcodes = Set<String>()

    init(delegate: ViewProtocol) {
        self.viewDelegate = delegate
    }

    private func searchCompleted(payload: String?, boundingBox: CGRect?, arFrame: ARFrame?) {
        guard let payload = payload, let boundingBox = boundingBox, let arFrame = arFrame else { return }
        guard isNewBarcode(payload) else { return }

        let flippedBoundingBox = flipCoordicates(of: boundingBox)
        let centerPoint = CGPoint(x: flippedBoundingBox.midX, y: flippedBoundingBox.midY)
        guard let hitTestResult = hitTestOnPlane(point: centerPoint, arFrame: arFrame) else { return }

        newBarcodeFound(payload)
        let planeNode = preparePlaneNode(hitTestResult: hitTestResult)
        viewDelegate.addNode(planeNode)
    }

    private func isNewBarcode(_ payload: String) -> Bool {
        guard !knownBarcodes.contains(payload) else {
            print("Info: already exists")
            return false
        }
        return true
    }

    private func flipCoordicates(of rect: CGRect) -> CGRect {
        var flippedRect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
        flippedRect = flippedRect.applying(CGAffineTransform(translationX: 0, y: 1))
        return flippedRect
    }

    private func hitTestOnPlane(point: CGPoint, arFrame: ARFrame) -> ARHitTestResult? {
        let allHitTestResults = arFrame.hitTest(point, types: [.existingPlaneUsingExtent])
        guard let result = allHitTestResults.first else {
            print("Warning: no hit")
            return nil
        }
        guard (result.anchor as? ARPlaneAnchor) != nil else {
            print("Warning: not a plane anchor")
            return nil
        }
        return result
    }

    private func preparePlaneNode(hitTestResult: ARHitTestResult) -> SCNNode {
        let transform: matrix_float4x4 = hitTestResult.worldTransform
        let worldCoord: SCNVector3 = SCNVector3Make(transform.columns.3.x,
                                                    transform.columns.3.y,
                                                    transform.columns.3.z)

        let plane = SCNPlane(width: 0.05, height: 0.03)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green.withAlphaComponent(0.8)
        plane.materials = [material]

        let node = SCNNode()
//        node.transform = SCNMatrix4MakeRotation(-.pi / 2, 0, 0, 1)
        node.transform = SCNMatrix4Identity
        node.geometry = plane
        node.position = worldCoord

        return node
    }

    private func newBarcodeFound(_ payload: String) {
        knownBarcodes.insert(payload)
        print("new barcode: \(payload)")
    }
}

extension ViewModel: ViewModelProtocol {
    func process(arFrame: ARFrame) {
        detector.search(in: arFrame)
    }
}
