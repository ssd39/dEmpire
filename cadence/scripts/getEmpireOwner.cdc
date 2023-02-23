import "DEmpire"

pub fun main(empireId: UInt256): Address? {
    return DEmpire.empireAccountMap[empireId] 
}