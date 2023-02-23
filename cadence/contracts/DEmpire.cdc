import DEToken from "./DEToken.cdc"
import DEAssets from "./DEAssets.cdc"

pub contract DEmpire {

    pub let EmpireStoragePath: StoragePath
    pub let EmpirePublicRefPath: PublicPath
    pub let EmpirePrivateRefPath: PrivatePath
    pub var currentEmpireId: UInt256;
    pub var empireAccountMap: {UInt256: Address};
    pub event EmpireStarted(account: Address)

    pub resource interface EmpireBuildings {
        pub let buildingsPosition : {UInt: [[Fix64]] }
    }

    pub resource interface EmpireUpdate {
        pub fun saveBuildingPositions(acc: AuthAccount, data: {UInt: [[Fix64]] })
    }

    pub resource Empire : EmpireBuildings, EmpireUpdate { 
        pub let buildingsPosition : {UInt: [[Fix64]] }
        init(){
            self.buildingsPosition = {}
        }

        pub fun saveBuildingPositions(acc: AuthAccount, data: {UInt: [[Fix64]] }){
            let assetTypes = data.keys
            for asset in assetTypes {
                let positions = data[asset]!
                DEAssets.lockAsset(acc:  acc, typeId: asset, count: UInt64(positions.length))
                self.buildingsPosition[asset] = positions
            }
        }
    }

    // currently this functions is getting called from client and no context of fight given
    // In future there will be fight resource and oralce/trusted party which will call this function
    pub fun endFight(buildingDestroyed: UInt64, troopsDestroyed: UInt64, myAddress: Address, opponentAddress: Address){
        DEToken.credit(acc: myAddress, amount: UFix64(buildingDestroyed * UInt64(50)) )
        DEToken.credit(acc: opponentAddress, amount: UFix64(buildingDestroyed * UInt64(15)))
    }

    init() {
        self.EmpireStoragePath = /storage/Empire
        self.EmpirePublicRefPath = /public/EmpireRef
        self.EmpirePrivateRefPath = /private/EmpireRef
        self.currentEmpireId = 0
        self.empireAccountMap = {}
    }

    pub fun startGame(acc: AuthAccount){
        pre{
            acc.type(at: self.EmpireStoragePath) == nil: "Game already started!"
        }
        post{
            self.currentEmpireId == before(self.currentEmpireId) + 1:
            "empire id is not incremented by one"
        }
        let newEmpire <- create Empire()
        // only for testnet
        DEToken.faucet(acc: acc, amount: 1000.0)
        self.empireAccountMap[self.currentEmpireId] = acc.address
        self.currentEmpireId = self.currentEmpireId + 1
        acc.save<@Empire>(<-newEmpire, to: self.EmpireStoragePath)
        acc.link<&Empire{EmpireUpdate}>(self.EmpirePrivateRefPath, target: self.EmpireStoragePath)
        acc.link<&Empire{EmpireBuildings}>(self.EmpirePublicRefPath, target: self.EmpireStoragePath)
        emit EmpireStarted(account: acc.address)
    }
}
 