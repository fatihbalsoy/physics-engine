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
    private var id: Int!
    public var mass: Double!
    public var radius: Double!
    public var velocity: SCNVector3!
    public var node: SCNNode!
    
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
    
    init(_ id: Int, mass: Double, radius: Double, position: SCNVector3, velocity: SCNVector3) {
        self.id = id
        self.mass = mass
        self.radius = radius
        self.velocity = velocity
        
        self.node = SCNNode(geometry: SCNSphere(radius: radius))
        self.position = position
    }
    
    func animate(planets: [Planet]) {
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
            
            // Not accurate
//            self.position = self.position + acceleration
//            self.position.x -= radius + planet.velocity.x
//            self.position.y -= radius + planet.velocity.y
//            velocity = SCNVector3(-planet.velocity.x, 0, -planet.velocity.y)
        } else {
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
        return SCNVector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }
    
    public static func *(lhs: Double, rhs: SCNVector3) -> SCNVector3 {
        return rhs * lhs
    }
    
    // DIVISION
    public static func /(lhs: SCNVector3, rhs: Double) -> SCNVector3 {
        return SCNVector3(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }
    
    public static func /(lhs: Double, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs / rhs.x, lhs / rhs.y, lhs / rhs.y)
    }
    
    // DOT PRODUCT
    public static func •(lhs: SCNVector3, rhs: SCNVector3) -> Double {
        return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
    }
    
    // MAGNITUDE
    public func magnitude() -> Double {
        return sqrt(pow(self.x, 2) + pow(self.y, 2) + pow(self.z, 2))
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
