import DEToken from "./DEToken.cdc"


pub contract DEmpire {

    pub let EmpireStoragePath: StoragePath
    pub let EmpirePublicRefPath: PublicPath
    pub var currentEmpireId: UInt256;
    pub var empireAccountMap: {UInt256: Address};

    pub resource interface EmpireBuildings {
        pub let buildingsPosition : {UInt: [[Fix64]] }
    }

    pub resource Empire : EmpireBuildings { 
        pub let buildingsPosition : {UInt: [[Fix64]] }
        init(){
            self.buildingsPosition = {}
        }
    }

    init() {
        self.EmpireStoragePath = /storage/Empire
        self.EmpirePublicRefPath = /public/EmpireRef
        self.currentEmpireId = 0
        self.empireAccountMap = {}
    }

    pub fun startGame(){
        pre{
            self.account.type(at: self.EmpireStoragePath) == nil: "Game already started!"
        }
        post{
            self.currentEmpireId == before(self.currentEmpireId) + 1:
            "empire id is not incremented by one"
        }
        let newEmpire <- create Empire()
        // only for testnet
        DEToken.faucet(amount: 1000.0)
        self.empireAccountMap[self.currentEmpireId] = self.account.address
        self.currentEmpireId = self.currentEmpireId + 1
        self.account.save<@Empire>(<-newEmpire, to: self.EmpireStoragePath)
        self.account.link<&Empire{EmpireBuildings}>(self.EmpirePublicRefPath, target: self.EmpireStoragePath)
        let tokneRef = self.account.getCapability<&DEToken.Vault{DEToken.Receiver, DEToken.Balance}>(DEToken.ReceiverPublicPath)
        if(!tokneRef.check()){
            self.account.link<&DEToken.Vault{DEToken.Receiver, DEToken.Balance}>(DEToken.ReceiverPublicPath, target: DEToken.VaultStoragePath)
        }
    }
}
 