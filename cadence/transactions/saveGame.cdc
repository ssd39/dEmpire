// read more about Cadence transactions here https://developers.flow.com/cadence/language/transactions
import "DEmpire"

transaction() {
    let acc: AuthAccount

    prepare(signer: AuthAccount) {
        self.acc = signer    
    }

    pre {}

    execute {
        // save the resource to the storage, read more about it here https://developers.flow.com/cadence/language/accounts#account-storage
        var ref = self.acc.getCapability<&DEmpire.Empire{DEmpire.EmpireUpdate}>(DEmpire.EmpirePrivateRefPath)
        if ref.check() {
            let borrowdRef = ref.borrow()!
            return borrowdRef.saveBuildingPositions(acc: self.acc, data: {1: [[Fix64(0.0)]]})
        }else{
            panic("game not found")
        }
    }

    post {}
}
