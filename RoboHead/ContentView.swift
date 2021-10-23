//
//  ContentView.swift
//  RoboHead
//
//  Created by Николай Никитин on 20.10.2021.
//

import ARKit
import SwiftUI
import RealityKit

//MARK: - Properties
var arView: ARView!

//MARK: - ContentView
struct ContentView : View {
  var body: some View {
    return ARViewContainer().edgesIgnoringSafeArea(.all)
  }
}

//MARK: - ARViewContainer
struct ARViewContainer: UIViewRepresentable {

  // Makes user interface view. By default there is nothing
  func makeUIView(context: Context) -> ARView {
    arView = ARView(frame: .zero)
    arView.session.delegate = context.coordinator
    return arView
  }

  // Updating user interface view
  func updateUIView(_ uiView: ARView, context: Context) {
    uiView.scene.anchors.removeAll()

    let configuration = ARFaceTrackingConfiguration()
    configuration.isLightEstimationEnabled = true
    configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
    uiView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    var anchor: RealityKit.HasAnchoring
    anchor = try! Experience.loadRoboHead()
    uiView.scene.addAnchor(anchor)
  }

  func makeCoordinator() -> ARDelegateHandler {
    ARDelegateHandler(self)
  }

  class ARDelegateHandler: NSObject, ARSessionDelegate {

    var arViewContainer: ARViewContainer
    var sparking = true
    var lasers = true

    init(_ control: ARViewContainer){
      arViewContainer = control
      super.init()
    }

    // Translate to radians
    func degToRad(_ value: Float) -> Float{
      return value * .pi / 180
    }

    // Animates red lights over users head
    func makeRedLight() -> PointLight {
      let redLight = PointLight()
      redLight.light.color = .red
      redLight.light.intensity = 100_000
      return redLight
    }

    // Animates robot's head moving
    func animateRobot(faceAnchor: ARFaceAnchor) {

      // Take fase anchor as robot's head node
      guard  let robot = arView.scene.anchors.first(where: { $0 is Experience.RoboHead }) as? Experience.RoboHead else { return }

      //Recognising face elements and takes their positions
      let blendShapes = faceAnchor.blendShapes
      guard
        let jawOpen = blendShapes[.jawOpen]?.floatValue,
          let eyeBlinkL = blendShapes[.eyeBlinkLeft]?.floatValue,
          let eyeBlinkR = blendShapes[.eyeBlinkRight]?.floatValue,
          let browInnerUp = blendShapes[.browInnerUp]?.floatValue,
          let browL = blendShapes[.browDownLeft]?.floatValue,
          let browR = blendShapes[.browDownRight]?.floatValue
      else { return }

      if sparking && jawOpen > 0.7 && browInnerUp < 0.5 {
        sparking = false
        let lightR = makeRedLight()
        let lightL = makeRedLight()
        robot.eyeL?.addChild(lightL)
        robot.eyeR?.addChild(lightR)

        robot.notifications.spark.post()

        robot.actions.sparkingEnded.onAction = { _ in
          lightR.removeFromParent()
          lightL.removeFromParent()
          self.sparking = true
        }
      }

      if lasers && browInnerUp > 0.8 {
        lasers = false
        let lightR = makeRedLight()
        let lightL = makeRedLight()
        robot.eyeL?.addChild(lightL)
        robot.eyeR?.addChild(lightR)

        robot.notifications.laser.post()

        robot.actions.laserEnded.onAction = { _ in
          lightR.removeFromParent()
          lightL.removeFromParent()
          self.lasers = true
        }
      }

      // Orientates eye lids using quaternions (no, i'm not so smart!)
      robot.eyeLidR?.orientation = simd_mul(
        simd_quatf(
          angle: degToRad(-120 + (90 * eyeBlinkR)),
          axis: [1,0,0]),
        simd_quatf(
          angle: degToRad((-90 * browR) - (-30 * browInnerUp)),
          axis: [0,0,1]))
      robot.eyeLidL?.orientation = simd_mul(
        simd_quatf(
          angle: degToRad(-120 + (90 * eyeBlinkL)),
          axis: [1,0,0]),
        simd_quatf(
          angle: degToRad((90 * browL) - (30 * browInnerUp)),
          axis: [0,0,1]))
      robot.jaw?.orientation = simd_quatf(
        angle: degToRad(-100 + (60 * jawOpen)),
        axis: [1,0,0])
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]){
      guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
      animateRobot(faceAnchor: faceAnchor)
    }
  }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
#endif
