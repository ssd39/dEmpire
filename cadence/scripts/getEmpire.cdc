import "DEmpire"

pub fun main(acc: Address): {UInt: [[Fix64]]}? {
    let publicAcc = getAccount(acc)
    var ref = publicAcc.getCapability<&DEmpire.Empire{DEmpire.EmpireBuildings}>(DEmpire.EmpirePublicRefPath)
    if ref.check(){
        let borrowdRef = ref.borrow()!
        return borrowdRef.buildingsPosition
    }
    return nil
}
