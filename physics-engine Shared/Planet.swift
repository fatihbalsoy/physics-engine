//
//  Planet.swift
//  physics-engine iOS
//
//  Created by Fatih Balsoy on 5/1/22.
//

import Foundation
import SceneKit

public let gravitationalConstant = 6.67e-11
public class Planet {
    public var id: Int!
    public var mass: Double!
    public var radius: Double!
    public var velocity: SCNVector3!
    public var node: SCNNode!
    public var collided: [Planet] = []
    public var scene: SCNScene!
//    public var closest: Planet?
    
    public var position: SCNVector3 {
        set {
            self.node.position = newValue
        }
        get {
            return self.node.position
        }
    }
    
    public static func ==(lhs: Planet, rhs: Planet) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func !=(lhs: Planet, rhs: Planet) -> Bool {
        return lhs.id != rhs.id
    }
    
    init(_ id: Int, mass: Double, radius: Double, position: SCNVector3, velocity: SCNVector3, scene: SCNScene, color: SCNColor? = SCNColor(white: 1, alpha: 1)) {
        self.id = id
        self.mass = mass
        self.radius = radius
        self.velocity = velocity
        
        self.node = SCNNode(geometry: SCNSphere(radius: radius))
        self.node.geometry?.firstMaterial?.diffuse.contents = color
        self.position = position
        self.node.castsShadow = true
        createTrail()
        
        self.scene = scene
    }
    
    private func createTrail() {
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 10000 // 10000
        particleSystem.particleLifeSpan = 100
        particleSystem.warmupDuration = 0.5
        particleSystem.emissionDuration = 500.0
        particleSystem.loops = true
        particleSystem.particleSize = 0.5
        particleSystem.particleColor = SCNColor(white: 1, alpha: 0.01) // a:0.01
        particleSystem.birthDirection = .random
        particleSystem.speedFactor = 7
        particleSystem.emittingDirection = SCNVector3(0,0,0)
        particleSystem.emitterShape = .some(SCNSphere(radius: 1.0))
        particleSystem.spreadingAngle = 30
//        particleSystem.acceleration = SCNVector3(0.0,-1.8,0.0)
        self.node.addParticleSystem(particleSystem)
    }
    
    private func collisionParticle(with planet: Planet) {
        if (collided.contains(where: { p in
            return p == planet
        })) {
            return
        } else {
            collided.append(planet)
        }
        
        let particleSystem = SCNParticleSystem()
        let mag = velocity.magnitude()
        particleSystem.birthRate = mag * 1000 // 10000
        particleSystem.particleLifeSpan = 100
        particleSystem.warmupDuration = 0.5
        particleSystem.emissionDuration = 5.0
        particleSystem.loops = false
        particleSystem.particleSize = 1
        particleSystem.particleColor = (node.geometry?.firstMaterial?.diffuse.contents as? SCNColor) ?? SCNColor(white: 1, alpha: 1)
        particleSystem.birthDirection = .random
        particleSystem.speedFactor = 10
        particleSystem.emittingDirection = SCNVector3(0,0,1)
        particleSystem.emitterShape = .some(SCNSphere(radius: radius))
        particleSystem.spreadingAngle = 360
        particleSystem.particleVelocity = mag * 10
        particleSystem.particleVelocityVariation = 100
        if (self.node.particleSystems?.count ?? 0) < 10 {
            self.node.addParticleSystem(particleSystem)
        }
    }
    
    private func addLight() {
        let lightNode = SCNNode()
        let light = SCNLight()
        light.type = .ambient
        light.intensity = 100
        light.shadowRadius = 1
        light.color = SCNColor(white: 0.5, alpha: 1)
        light.castsShadow = true
        lightNode.light = light
        self.node.addChildNode(lightNode)
    }
    
    func animate(_ planets: [Planet]) {
        // Probably not the fastest way to animate all planets
        planets.forEach { p in
            if p != self {
                let nume = (gravitationalConstant * self.mass * p.mass)
                let deno = pow(distance(to: p), 2)
                let F = nume / deno
                self.apply(force: F, towards: p)
            }
        }
    }
    
    func distance(to planet: Planet) -> Double {
        return self.position.distance(to: planet.position)
    }
    
    func colliding(with planet: Planet) -> Bool {
        return distance(to: planet) <= radius + planet.radius
    }
    
    /**
     - planet: The other planet affecting this planet
     - force: The force being applied by the other planet
     */
    func apply(force: Double, towards planet: Planet) {
        let direction = planet.position - self.position
        let forceVector = direction * -force
        let acceleration = forceVector / mass
//        self.node.particleSystems?.first?.birthRate = velocity.magnitude() * 50000 // Too Laggy
        
//        if let c = closest {
//            if (planet.distance(to: self) < c.distance(to: self)) {
//                self.closest = planet
//            }
//        } else {
//            closest = planet
//        }
//        self.position = self.position - forceVector
//        print("force:", force)
//        print("acceleration:", acceleration)
        
        if (colliding(with: planet)) {
            // Collisions and Momentum
            // Σ mv_i = Σ mv_f
            // mv_i1 + mv_i2 = mv_f1 + mv_f2
            // Need angles: https://www.nayuki.io/page/angles-in-elastic-two-body-collisions
            
            // Conservation of Momemtum
            // Σ (1/2)mv_i^2 = Σ (1/2)mv_f^2
            // (1/2)mv_i1^2 + (1/2)mv_i2^2 = (1/2)mv_f1^2 + (1/2)mv_f2^2
            
//            print("Planet:",id!)
//            print("== BEFORE ==")
//            print("Velocity:",velocity!)
//            print("Position:",position)
            
            collisionParticle(with: planet)
            
            let massDiv = (mass - planet.mass)/(mass + planet.mass)
            let massDiv2 = (2*planet.mass)/(mass + planet.mass)
            velocity = massDiv * velocity + massDiv2 * planet.velocity
//            velocity = -1 * velocity + acceleration
            self.position = position + velocity
            
            let massDivP2 = (planet.mass - mass)/(mass + planet.mass)
            let massDiv2P2 = (2*mass)/(mass + planet.mass)
            planet.velocity = massDivP2 * planet.velocity + massDiv2P2 * velocity
//            planet.velocity = -1 * planet.velocity + acceleration
            planet.position = planet.position + planet.velocity
            
//            print("== AFTER ==")
//            print("Velocity:",velocity!)
//            print("Position:",position)
//            pause()
            
            // Not accurate
//            self.position = self.position + acceleration
//            self.position.x -= radius + planet.velocity.x
//            self.position.y -= radius + planet.velocity.y
//            velocity = SCNVector3(-planet.velocity.x, 0, -planet.velocity.y)
        } else {
            collided.removeAll { p in
                p == planet
            }
            self.position = position + velocity
            velocity = velocity - acceleration
        }
    }
}





infix operator •
extension SCNVector3 {
    // ADD AND SUBTRACT
    public static func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
    
    public static func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    // MULTIPLICATION
    public static func *(lhs: SCNVector3, rhs: Double) -> SCNVector3 {
        return SCNVector3(Double(lhs.x) * rhs, Double(lhs.y) * rhs, Double(lhs.z) * rhs)
    }
    
    public static func *(lhs: Double, rhs: SCNVector3) -> SCNVector3 {
        return rhs * lhs
    }
    
    // DIVISION
    public static func /(lhs: SCNVector3, rhs: Double) -> SCNVector3 {
        return SCNVector3(Double(lhs.x) / rhs, Double(lhs.y) / rhs, Double(lhs.z) / rhs)
    }
    
    public static func /(lhs: Double, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs / Double(rhs.x), lhs / Double(rhs.y), lhs / Double(rhs.y))
    }
    
    // DOT PRODUCT
    public static func •(lhs: SCNVector3, rhs: SCNVector3) -> Double {
        return Double(lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z)
    }
    
    // MAGNITUDE
    public func magnitude() -> Double {
        return Double(sqrt(pow(self.x, 2) + pow(self.y, 2) + pow(self.z, 2)))
    }
    
    // DISTANCE
    func distance(to vector: SCNVector3) -> Double {
        let d = sqrt(pow(vector.x - self.x, 2) +
                     pow(vector.y - self.y, 2) +
                     pow(vector.z - self.z, 2))
        return Double(d)
    }
    
    // PROJECTION
    public func project(onto vector: SCNVector3) -> SCNVector3 {
        // proj(b, a) = (a•b)
        let dot = self • vector
        let mag = pow(vector.magnitude(), 2)
        return (dot / mag) * vector
    }
    
    // ANGLE
    public func angle(between vector: SCNVector3) -> Double {
        // cosØ = dot/mag
        // dot = mag*cosØ
        // arccos(dot/mag) = Ø
        let dot = self • vector
        let mag = self.magnitude() * vector.magnitude()
        let angle = acos(dot/mag)
        return angle
    }
}
