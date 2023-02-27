// read more about Cadence transactions here https://developers.flow.com/cadence/language/transactions
import "DEmpire"
import "DEAssets"
import "DEToken"
import "NonFungibleToken"
import "MetadataViews"
import "FungibleToken"

transaction(typeId: UInt, amount: UFix64){
    let acc: AuthAccount

    prepare(signer: AuthAccount) {
        self.acc = signer

        let isCollection =  self.acc.type(at: DEAssets.CollectionStoragePath)
        if isCollection == nil{
            let collection <- DEAssets.createEmptyCollection()
            self.acc.save(<-collection, to: DEAssets.CollectionStoragePath)
        }

        let ref = self.acc.getCapability<&DEAssets.Collection{NonFungibleToken.CollectionPublic, DEAssets.DEAssetsCollectionPublic, MetadataViews.ResolverCollection}>(DEAssets.CollectionPublicPath)
        if !ref.check(){
            self.acc.link<&DEAssets.Collection{NonFungibleToken.CollectionPublic, DEAssets.DEAssetsCollectionPublic, MetadataViews.ResolverCollection}>(
                DEAssets.CollectionPublicPath,
                target: DEAssets.CollectionStoragePath
            )
        }  
    }

    pre {}

    execute {
        // save the resource to the storage, read more about it here https://developers.flow.com/cadence/language/accounts#account-storage
        var ref = self.acc.getCapability<&DEToken.Vault{FungibleToken.Provider}>(DEToken.ProviderPrivatePath)
        if !ref.check() {
            self.acc.link<&DEToken.Vault{FungibleToken.Provider}>(
                DEToken.ProviderPrivatePath,
                target: DEToken.VaultStoragePath
            )
            ref = self.acc.getCapability<&DEToken.Vault{FungibleToken.Provider}>(DEToken.ProviderPrivatePath)
        }
        DEAssets.buy(ownerAddress: self.acc.address, vault: <- ref.borrow()!.withdraw(amount: amount), typeId: typeId)
    }

    post {}
}
