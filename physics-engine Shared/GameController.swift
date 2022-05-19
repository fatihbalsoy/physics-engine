//
//  GameController.swift
//  physics-engine Shared
//
//  Created by Fatih Balsoy on 5/1/22.
//

import SceneKit

#if os(watchOS)
    import WatchKit
#endif

#if os(macOS)
    typealias SCNColor = NSColor
#else
    typealias SCNColor = UIColor
#endif

class GameController: NSObject, SCNSceneRendererDelegate {

    let scene: SCNScene
    let sceneRenderer: SCNSceneRenderer
    
    var planets = [Planet]()
    var lineNode: SCNNode!
    var lineNode2: SCNNode!
    
    var cameraNode: SCNNode!
    
    init(sceneRenderer renderer: SCNSceneRenderer) {
        sceneRenderer = renderer
        scene = SCNScene(named: "Art.scnassets/ship.scn")!
        
        super.init()
        
        sceneRenderer.delegate = self
        
        if let c = scene.rootNode.childNode(withName: "camera", recursively: true) {
            cameraNode = c
        }
        
        let planet1 = Planet(1, mass: 4e9, radius: 10,
                             position: SCNVector3(-10,0,-10),
                             velocity: SCNVector3(0,0,0))
        let planet2 = Planet(2, mass: 200, radius: 5,
                             position: SCNVector3(50,0,50),
                             velocity: SCNVector3(-8,-8,5))
//        let planet3 = Planet(3, mass: 400, radius: 8,
//                             position: SCNVector3(100,0,100),
//                             velocity: SCNVector3(8,8,2))
        planets = [planet1, planet2]
        
        planets.forEach { planet in
            scene.rootNode.addChildNode(planet.node)
        }
        
        planets[0].node.runAction(SCNAction.repeatForever(.rotateBy(x: 0, y: 0, z: 0, duration: 1)))
        
//        lineNode = SCNNode(geometry: SCNPlane())
//        scene.rootNode.addChildNode(lineNode)
        
        sceneRenderer.scene = scene
    }
    
    func highlightNodes(atPoint point: CGPoint) {
        let hitResults = self.sceneRenderer.hitTest(point, options: [:])
        for result in hitResults {
            // get its material
            guard let material = result.node.geometry?.firstMaterial else {
                return
            }
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = SCNColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = SCNColor.red
            
            SCNTransaction.commit()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Called before each frame is rendered
        planets.forEach { planet in
            planet.animate(planets: planets)
        }
        
        let mid = (planets[0].position + planets[1].position) / 2
        let center = mid
        cameraNode.position = center
//        cameraNode.position.y = planets[0].position.y + planets[0].distance(to: planets[1]) * 2
        cameraNode.position.y = center.y + 500
        cameraNode.look(at: center)
    }

}
