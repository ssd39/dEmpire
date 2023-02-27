// read more about Cadence transactions here https://developers.flow.com/cadence/language/transactions
import "DEmpire"
import "DEAssets"

transaction {
    let acc: AuthAccount

    prepare(signer: AuthAccount) {
        self.acc = signer    
    }

    pre {}

    execute {
        // save the resource to the storage, read more about it here https://developers.flow.com/cadence/language/accounts#account-storage
        let collection <- self.acc.load<@DEAssets.Collection>(from: DEAssets.CollectionStoragePath) ?? panic("collection not found")
        let ref = self.acc.getCapability<&DEmpire.Empire{DEmpire.EmpireUpdate}>(DEmpire.EmpirePrivateRefPath)
        if ref.check() {
            let borrowdRef = ref.borrow()!
            let updatedCollection <- borrowdRef.saveBuildingPositions(assetCollection: <-collection, data: {1: [[Fix64(0.0)]]})
            self.acc.save(<-updatedCollection, to: DEAssets.CollectionStoragePath)
        }else{
            panic("private reference to empire not found")
        }
    }

    post {}
}
