// read more about Cadence transactions here https://developers.flow.com/cadence/language/transactions
import "DEmpire"

transaction(buildingDestroyed: UInt64, troopsDestroyed: UInt64, opponentAddress: Address) {
    let acc: AuthAccount

    prepare(signer: AuthAccount) {
        self.acc = signer    
    }

    pre {}

    execute {
        DEmpire.endFight(buildingDestroyed: buildingDestroyed, troopsDestroyed: troopsDestroyed, myAddress: self.acc.address, opponentAddress: opponentAddress)
    }

    post {}
}
