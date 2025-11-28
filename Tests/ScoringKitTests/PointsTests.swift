import Testing
@testable import ScoringKit

@Suite("Points Tests")
struct PointsTests {
    
    @Suite("Initializers")
    struct InitializerTests {
        @Test func defaultInitializer() {
            let points = Points()
            #expect(points.numerator == 0)
            #expect(points.denominator == 0)
        }
        
        @Test func integerInitializer() {
            let points1 = Points(5)
            #expect(points1.numerator == 5)
            #expect(points1.denominator == 1)
            
            let points2 = Points(42)
            #expect(points2.numerator == 42)
            #expect(points2.denominator == 1)
            
            let points3 = Points(0)
            #expect(points3.numerator == 0)
            #expect(points3.denominator == 1)
            
            let points4 = Points(-10)
            #expect(points4.numerator == -10)
            #expect(points4.denominator == 1)
        }
        
        @Test func numeratorDenominatorInitializer() {
            let points1 = Points(numerator: 3, denominator: 4)
            #expect(points1.numerator == 3)
            #expect(points1.denominator == 4)
            
            let points2 = Points(numerator: 10, denominator: 5)
            #expect(points2.numerator == 10)
            #expect(points2.denominator == 5)
            
            let points3 = Points(numerator: 0, denominator: 1)
            #expect(points3.numerator == 0)
            #expect(points3.denominator == 1)
            
            let points4 = Points(numerator: -5, denominator: 2)
            #expect(points4.numerator == -5)
            #expect(points4.denominator == 2)
        }
    }
    
    @Suite("Addition Operator")
    struct AdditionOperatorTests {
        @Test func basicAddition() {
            let points1 = Points(5)
            let points2 = Points(3)
            let result = points1 + points2
            
            #expect(result.numerator == 8)
            #expect(result.denominator == 2)
        }
        
        @Test func withFractions() {
            let points1 = Points(numerator: 1, denominator: 2)
            let points2 = Points(numerator: 1, denominator: 3)
            let result = points1 + points2
            
            #expect(result.numerator == 2)
            #expect(result.denominator == 5)
        }
        
        @Test func withDifferentDenominators() {
            let points1 = Points(numerator: 3, denominator: 4)
            let points2 = Points(numerator: 1, denominator: 2)
            let result = points1 + points2
            
            #expect(result.numerator == 4)
            #expect(result.denominator == 6)
        }
        
        @Test func withZero() {
            let points1 = Points(5)
            let points2 = Points()
            let result = points1 + points2
            
            #expect(result.numerator == 5)
            #expect(result.denominator == 1)
        }
        
        @Test func commutative() {
            let points1 = Points(3)
            let points2 = Points(7)
            let result1 = points1 + points2
            let result2 = points2 + points1
            
            #expect(result1.numerator == result2.numerator)
            #expect(result1.denominator == result2.denominator)
        }
        
        @Test func multipleAdditions() {
            let points1 = Points(1)
            let points2 = Points(2)
            let points3 = Points(3)
            let result = points1 + points2 + points3
            
            #expect(result.numerator == 6)
            #expect(result.denominator == 3)
        }
    }
    
    @Suite("In-Place Addition Operator")
    struct InPlaceAdditionTests {
        @Test func basic() {
            var points = Points(5)
            points += Points(3)
            
            #expect(points.numerator == 8)
            #expect(points.denominator == 2)
        }
        
        @Test func withFractions() {
            var points = Points(numerator: 1, denominator: 2)
            points += Points(numerator: 1, denominator: 3)
            
            #expect(points.numerator == 2)
            #expect(points.denominator == 5)
        }
        
        @Test func multipleOperations() {
            var points = Points(1)
            points += Points(2)
            points += Points(3)
            
            #expect(points.numerator == 6)
            #expect(points.denominator == 3)
        }
        
        @Test func withZero() {
            var points = Points(10)
            points += Points()
            
            #expect(points.numerator == 10)
            #expect(points.denominator == 1)
        }
    }
    
    @Suite("Properties and Behavior")
    struct PropertiesTests {
        @Test func propertyModification() {
            var points = Points(5)
            
            #expect(points.numerator == 5)
            #expect(points.denominator == 1)
            
            points.numerator = 10
            #expect(points.numerator == 10)
            #expect(points.denominator == 1)
            
            points.denominator = 2
            #expect(points.numerator == 10)
            #expect(points.denominator == 2)
        }
        
        @Test func valueTypeBehavior() {
            let points1 = Points(5)
            var points2 = points1
            
            points2.numerator = 10
            
            #expect(points1.numerator == 5)
            #expect(points2.numerator == 10)
        }
    }
}
