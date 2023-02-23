import "DEToken"
import "FungibleToken"

pub fun main(acc: Address): UFix64? {
    let publicAcc = getAccount(acc)
    var ref = publicAcc.getCapability<&DEToken.Vault{FungibleToken.Balance}>(DEToken.VaultPublicPath)
    if ref.check() {
        let borrowdRef = ref.borrow()!
        return borrowdRef.balance
    }
    return nil
}
