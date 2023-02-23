// read more about Cadence transactions here https://developers.flow.com/cadence/language/transactions
import "DEmpire"

transaction {
    let acc: AuthAccount

    prepare(signer: AuthAccount) {
        self.acc = signer    
    }

    pre {}

    execute {
        DEmpire.startGame(acc: self.acc)
    }

    post {}
}
