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
    import AppKit
    typealias SCNTapGestureRecognizer = NSClickGestureRecognizer
#else
    typealias SCNColor = UIColor
    import UIKit
    typealias SCNTapGestureRecognizer = UITapGestureRecognizer
#endif

class GameController: NSObject, SCNSceneRendererDelegate {

    let scene: SCNScene
    let sceneRenderer: SCNSceneRenderer
    
    var planetToLookAt: Planet!
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
        
//        let planet1 = Planet(1, mass: 4e9, radius: 10,
//                             position: SCNVector3(-10,0,-10),
//                             velocity: SCNVector3(0,0,0))
//        let planet2 = Planet(2, mass: 2e9, radius: 5,
//                             position: SCNVector3(50,0,50),
//                             velocity: SCNVector3(-0.2,-0.2,0.05))
////                             velocity: SCNVector3(0,0,0))
//        let planet3 = Planet(3, mass: 4e10, radius: 12,
//                             position: SCNVector3(100,0,100),
//                             velocity: SCNVector3(0,0,0))
        planets = []
//        planets.append(planet1)
//        planets.append(planet2)
//        planets.append(planet3)
        
        for i in 1...100 {
            print("Generating Planet #", i)
            let mass = Double.random(in: 1..<4e5)
            let radius = (mass / 4e5) * 10
            
            let vx = Double.random(in: -0.002..<0.002)
            let vy = Double.random(in: -0.002..<0.002)
            let vz = Double.random(in: -0.002..<0.002)
            let v = SCNVector3(vx, vy, vz)
            
            let px = Double.random(in: -2000..<2000)
            let py = Double.random(in: -2000..<2000)
            let pz = Double.random(in: -2000..<2000)
            let pos = SCNVector3(px, py, pz)
            
            let cr = Double.random(in: 0..<1)
            let cg = Double.random(in: 0..<1)
            let cb = Double.random(in: 0..<1)
            let color = SCNColor(red: cr, green: cg, blue: cb, alpha: 1)
            
            let p = Planet(i, mass: mass, radius: radius, position: pos, velocity: v, color: color)
            planets.append(p)
        }
        
        planets[0].node.addChildNode(cameraNode)
        planetToLookAt = planets[1]
        cameraNode.look(at: planetToLookAt.position)
        cameraNode.position.z = planets[0].radius
        
        planets.forEach { planet in
//            let lightNode = SCNNode()
//            let light = SCNLight()
//            light.type = .ambient
//            light.intensity = 100
//            light.shadowRadius = 1
//            light.color = SCNColor(white: 0.5, alpha: 1)
//            light.castsShadow = true
//            lightNode.light = light
//            planet.node.addChildNode(lightNode)
            
            createTrail(forNode: planet.node)
            planet.node.castsShadow = true
            scene.rootNode.addChildNode(planet.node)
        }
        planets[0].node.removeAllParticleSystems()
        
        planets[0].node.runAction(SCNAction.repeatForever(.rotateBy(x: 0, y: 0, z: 0, duration: 0.5)))
        
//        lineNode = SCNNode(geometry: SCNPlane())
//        scene.rootNode.addChildNode(lineNode)
        
        sceneRenderer.scene = scene
    }
    
    func createTrail(forNode: SCNNode) {
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 10000
        particleSystem.particleLifeSpan = 100
        particleSystem.warmupDuration = 0.5
        particleSystem.emissionDuration = 500.0
        particleSystem.loops = true
        particleSystem.particleSize = 0.5
        particleSystem.particleColor = SCNColor(white: 1, alpha: 0.01)
        particleSystem.birthDirection = .random
        particleSystem.speedFactor = 7
        particleSystem.emittingDirection = SCNVector3(0,0,0)
        particleSystem.emitterShape = .some(SCNSphere(radius: 1.0))
        particleSystem.spreadingAngle = 30
//        particleSystem.acceleration = SCNVector3(0.0,-1.8,0.0)
        forNode.addParticleSystem(particleSystem)
    }
    
    func setCamera(atPoint point: CGPoint) {
        let hitResults = self.sceneRenderer.hitTest(point, options: [:])
        for result in hitResults {
//            // get its material
//            guard let material = result.node.geometry?.firstMaterial else {
//                return
//            }
            
            for planet in planets.filter({$0.node.position.distance(to: result.node.position) == 0}) {
                print("Planet #", planet.id!)
                print("Mass:", planet.mass!)
                planet.mass = planet.mass * 2
                print("Mass:", planet.mass!)
                
                planetToLookAt = planet
                cameraNode.look(at: planet.position)
            }
        }
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
//        var total = SCNVector3(0,0,0)
        planets.forEach { planet in
            planet.animate(planets: planets)
//            total = total + planet.position
        }
        
//        let mid: SCNVector3 = total / Double(planets.count)
//        let center = mid
//        cameraNode.position = center
////        cameraNode.position.y = planets[0].position.y + planets[0].distance(to: planets[1]) * 2
//        cameraNode.position.y = center.y + 500
//        cameraNode.look(at: center)
        
        let pl = planetToLookAt
//        cameraNode.position = pl.position
//        cameraNode.position.y = pl.position.y + 500
        cameraNode.look(at: pl!.position)
        
//        print("===========")
//        print("Planet #",id)
//        print("Mass:",pl.mass!)
//        print("Radius:",pl.radius!)
//        print(pl.velocity!.magnitude().rounded(toPlaces: 2), "m/s")
//        print(pl.position.magnitude().rounded(), "m")
//        if let c = pl.closest {
//            print("Closest: #",c.id!,
//                  ", Distance:", c.distance(to: pl), "m")
//        }
    }

}
