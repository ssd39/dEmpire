import "DEAssets"

pub fun main(acc: Address): {UInt: UInt64}? {
    let publicAcc = getAccount(acc)
    var ref = publicAcc.getCapability<&DEAssets.Collection{DEAssets.DEAssetsCollectionPublic}>(DEAssets.CollectionPublicPath)
    if ref.check()  {
        let borrowdRef = ref.borrow()!
        return borrowdRef.availableAssets
    }
    return nil
}
