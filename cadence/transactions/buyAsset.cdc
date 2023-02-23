// read more about Cadence transactions here https://developers.flow.com/cadence/language/transactions
import "DEAssets"

transaction(typeId: UInt){
    let acc: AuthAccount

    prepare(signer: AuthAccount) {
        self.acc = signer    
    }

    pre {}

    execute {
        // save the resource to the storage, read more about it here https://developers.flow.com/cadence/language/accounts#account-storage
        DEAssets.buy(acc: self.acc, typeId: typeId)
    }

    post {}
}
