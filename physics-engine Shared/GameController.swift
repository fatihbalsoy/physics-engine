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
    typealias SCNFloat = CGFloat
    typealias SCNImage = NSImage
#else
    typealias SCNColor = UIColor
    import UIKit
    typealias SCNTapGestureRecognizer = UITapGestureRecognizer
    typealias SCNFloat = Float
    typealias SCNImage = UIImage
#endif

class GameController: NSObject, SCNSceneRendererDelegate {

    let scene: SCNScene
    let sceneRenderer: SCNSceneRenderer
    
    var planetToLookAt: Planet!
    var planetPOV: Planet!
    var planets = [Planet]()
    
    var cameraNode: SCNNode!
    
    init(sceneRenderer renderer: SCNSceneRenderer) {
        sceneRenderer = renderer
        scene = SCNScene(named: "Art.scnassets/ship.scn")!
        
        super.init()
        sceneRenderer.delegate = self
        
        // Get camera node
        if let c = scene.rootNode.childNode(withName: "camera", recursively: true) {
            cameraNode = c
        }
        
        // Randomly generate planets
        planets = []
        for i in 1...100 {
            print("Generating Planet #", i)
            let mass = Double.random(in: 1e4..<4e5)
            let radius = (mass / 4e5) * 20 // 10
            
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
            
            let p = Planet(i, mass: mass, radius: radius, position: pos, velocity: v, scene: scene, color: color)
            planets.append(p)
        }
        
        let realism = false
        if (realism) {
            // Milky Way
            scene.background.contents = SCNImage(named: "8k_stars_milky_way")
            
            // Earth (6e24) / 1e12 = 6e12
            let earth = Planet(planets.count, mass: 6e12, radius: 6731, position: SCNVector3(0,0,12000), velocity: SCNVector3(5,0,0), scene: scene, color: SCNColor(red: 0, green: 0, blue: 1, alpha: 1))
            earth.node.geometry?.firstMaterial?.diffuse.contents = SCNImage(named: "2k_earth_january")
            earth.node.geometry?.firstMaterial?.metalness.contents = SCNImage(named: "2k_earth_specular_map")
            earth.node.geometry?.firstMaterial?.clearCoatRoughness.contents = SCNImage(named: "2k_earth_specular_map")
            earth.node.geometry?.firstMaterial?.normal.contents = SCNImage(named: "2k_earth_normal_map")
            earth.node.geometry?.firstMaterial?.emission.contents = SCNImage(named: "world_emission_2k")
            planets.append(earth)
            
            // Moon (7e22) / 1e12 = 7e10
            let moon = Planet(planets.count, mass: 7e10, radius: 1737.4, position: SCNVector3(0,0,12000 + 384472), velocity: SCNVector3(7,0,0), scene: scene, color: SCNColor(white: 0.5, alpha: 1))
            moon.node.geometry?.firstMaterial?.diffuse.contents = SCNImage(named: "2k_moon")
            planets.append(moon)
        }
        
        // Setup camera at a planet
        planetPOV = planets[0]
        planetToLookAt = planets[planets.count - 1]
        planetPOV.node.addChildNode(cameraNode)
        cameraNode.position.z = SCNFloat(planetPOV.radius)
        planetPOV.node.removeAllParticleSystems()
        planetPOV.node.geometry?.firstMaterial?.diffuse.contents = SCNColor(white: 0, alpha: 0)
        cameraNode.look(at: planetToLookAt.position)
        
        // Add planets to scene
        planets.forEach { planet in
            scene.rootNode.addChildNode(planet.node)
        }
        
        // Run infinite action to get the scene to move
        planets[0].node.runAction(SCNAction.repeatForever(.rotateBy(x: 0, y: 0, z: 0, duration: 0.125)))
        
        sceneRenderer.scene = scene
    }
    
    func handleTap(atPoint point: CGPoint) {
        let hitResults = self.sceneRenderer.hitTest(point, options: [:])
        for result in hitResults {
            for planet in planets.filter({$0.node.position.distance(to: result.node.position) == 0}) {
                doubleMass(for: planet)
                setCamera(at: planet)
                highlightNode(of: planet)
            }
        }
    }
    
    func doubleMass(for planet: Planet) {
        print("Planet #", planet.id!)
        print("Mass:", planet.mass!)
        planet.mass = planet.mass * 2
        print("Mass:", planet.mass!)
    }
    
    func setCamera(at planet: Planet) {
        planetToLookAt = planet
        cameraNode.look(at: planet.position)
    }
    
    func highlightNode(of planet: Planet) {
        guard let material = planet.node.geometry?.firstMaterial else {
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
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Called before each frame is rendered
//        var total = SCNVector3(0,0,0)
        planets.forEach { planet in
            planet.animate(planets)
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
//        print(planetToLookAt.distance(to: planets[0]))
        
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
