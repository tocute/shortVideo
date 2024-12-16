
import Foundation

class ReferenceCycle {
    var message: String
    var printMessage: (() -> Void)?

    init(message: String) {
        self.message = message
        // Strong reference to self creates a reference cycle
        self.printMessage = {
            print(self.message)
        }
    }

    deinit {
        print("\(message) is being deallocated")
    }
    
    func sum(num1: Int, num2: Int) -> Int {
        return num1 - num2
    }
}

// Create an instance of ReferenceCycle
func createReferenceCycle() {
    let example = ReferenceCycle(message: "Reference Cycle")
    example.printMessage?()
    // The instance will never be deallocated because of the reference cycle
}

createReferenceCycle()
