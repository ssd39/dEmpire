import "DEmpire"
import "DEAssets"
import "DEToken"
import "NonFungibleToken"
import "MetadataViews"
import "FungibleToken"

transaction {
    let acc: AuthAccount

    prepare(signer: AuthAccount) {
        self.acc = signer

        let isCollection =  self.acc.type(at: DEAssets.CollectionStoragePath)
        if isCollection == nil{
            let collection <- DEAssets.createEmptyCollection()
            self.acc.save(<-collection, to: DEAssets.CollectionStoragePath)
        }

        var ref = self.acc.getCapability<&DEAssets.Collection{NonFungibleToken.CollectionPublic, DEAssets.DEAssetsCollectionPublic, MetadataViews.ResolverCollection}>(DEAssets.CollectionPublicPath)
        if !ref.check(){
            self.acc.link<&DEAssets.Collection{NonFungibleToken.CollectionPublic, DEAssets.DEAssetsCollectionPublic, MetadataViews.ResolverCollection}>(
                DEAssets.CollectionPublicPath,
                target: DEAssets.CollectionStoragePath
            )
        }

        let isVault =  self.acc.type(at: DEToken.VaultStoragePath)
        if isVault == nil{
            let vault <- DEToken.createEmptyVault()
            self.acc.save(<-vault, to: DEToken.VaultStoragePath)
        }

        let receiverRef = self.acc.getCapability<&DEToken.Vault{FungibleToken.Receiver}>(DEToken.ReceiverPublicPath)
        if !receiverRef.check(){
            // Create a public capability to the stored Vault that exposes
            // the `deposit` method through the `Receiver` interface.
            self.acc.link<&DEToken.Vault{FungibleToken.Receiver}>(
                DEToken.ReceiverPublicPath,
                target: DEToken.VaultStoragePath
            )
        }

        let vaultPublicRef = self.acc.getCapability<&DEToken.Vault{FungibleToken.Balance}>(DEToken.VaultPublicPath)
        if !vaultPublicRef.check(){
            // Create a public capability to the stored Vault that only exposes
            // the `balance` field and the `resolveView` method through the `Balance` interface
            self.acc.link<&DEToken.Vault{FungibleToken.Balance}>(
                DEToken.VaultPublicPath,
                target: DEToken.VaultStoragePath
            )
        }



    }

    execute {
        let newEmpire: @DEmpire.Empire  <- DEmpire.startGame(user: self.acc.address)
        self.acc.save<@DEmpire.Empire>(<-newEmpire, to: DEmpire.EmpireStoragePath)
        self.acc.link<&DEmpire.Empire{DEmpire.EmpireUpdate}>(DEmpire.EmpirePrivateRefPath, target: DEmpire.EmpireStoragePath)
        self.acc.link<&DEmpire.Empire{DEmpire.EmpireBuildings}>(DEmpire.EmpirePublicRefPath, target: DEmpire.EmpireStoragePath)
    }

    post {}
}
