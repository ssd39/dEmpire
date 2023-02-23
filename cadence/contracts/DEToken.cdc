pub contract DEToken {
    pub var totalSupply: UFix64

    pub let VaultStoragePath: StoragePath
    pub let ReceiverPublicPath: PublicPath

    /// The event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    /// The event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    /// The event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    /// The event that is emitted when new tokens are minted
    pub event TokensMinted(amount: UFix64)

    /// The event that is emitted when tokens are destroyed
    pub event TokensBurned(amount: UFix64)

    pub resource interface Provider {

        pub fun withdraw(amount: UFix64): @Vault {
            post {
                // `result` refers to the return value
                result.balance == amount:
                    "Withdrawal amount must be the same as the balance of the withdrawn Vault"
            }
        }
    }

    pub resource interface Receiver {
        pub fun deposit(from: @Vault)
    }

    pub resource interface Balance {

        /// The total balance of a vault
        ///
        pub var balance: UFix64

        init() {
            post {
                self.balance == 0.0:
                    "Vault must be initialized to 0 balance"
            }
        }
    }


    pub resource Vault: Provider, Receiver, Balance {

        /// The total balance of this vault
        pub var balance: UFix64

        /// Initialize the balance at resource creation time
        init() {
            self.balance = 0.0
        }

        access(contract) fun mint(amount: UFix64){
            post{
                self.balance==before(self.balance) + amount:
                "balance not updated"
            }
            self.balance = self.balance + amount
            DEToken.totalSupply = DEToken.totalSupply + amount
            emit TokensMinted(amount: amount)
        }

        pub fun withdraw(amount: UFix64): @DEToken.Vault {
            pre {
                self.balance >= amount:
                    "Amount withdrawn must be less than or equal than the balance of the Vault"
            }
            post {
                self.balance == before(self.balance) - amount:
                    "New Vault balance must be the difference of the previous balance and the withdrawn Vault"
            }

            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault()
        }

        pub fun deposit(from: @DEToken.Vault) {
            pre {
                from.isInstance(self.getType()): 
                    "Cannot deposit an incompatible token type"
            }
            post {
                self.balance == before(self.balance) + before(from.balance):
                    "New Vault balance must be the sum of the previous balance and the deposited Vault"
            }

            let vault <- from
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        destroy() {
            if self.balance > 0.0 {
                DEToken.totalSupply = DEToken.totalSupply - self.balance
            }
        }
    }

    access(account) fun faucet(amount: UFix64){
        post {
            self.totalSupply== before(self.totalSupply) + amount:
            "Total supply not updated"
        }
        let isTokenExsist = self.account.type(at: self.VaultStoragePath)
        if isTokenExsist != nil {
            let currentVault <- self.account.load<@Vault>(from: self.VaultStoragePath)
            currentVault?.mint(amount: amount)
            self.account.save(<-currentVault!, to: self.VaultStoragePath)
        } else {
            let vault <- create Vault()
            vault.mint(amount: amount)
            self.account.save(<-vault, to: self.VaultStoragePath)
        }
    }
    
    init() {
        self.totalSupply = 0.0
        self.VaultStoragePath = /storage/DETokenVault
        self.ReceiverPublicPath = /public/DETokenReceiver
        self.faucet(amount: 10000.0)
        self.account.link<&Vault{Receiver, Balance}>(self.ReceiverPublicPath, target: self.VaultStoragePath)
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
 