// read more about Cadence transactions here https://developers.flow.com/cadence/language/transactions
import "DEmpire"

transaction(buildingDestroyed: UInt64, troopsDestroyed: UInt64, opponentAddress: Address) {
    let acc: AuthAccount

    prepare(signer: AuthAccount) {
        self.acc = signer

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

    pre {}

    execute {
        DEmpire.endFight(buildingDestroyed: buildingDestroyed, troopsDestroyed: troopsDestroyed, myAddress: self.acc.address, opponentAddress: opponentAddress)
    }

    post {}
}
