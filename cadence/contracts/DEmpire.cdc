import DEToken from "./DEToken.cdc"
import DEAssets from "./DEAssets.cdc"
import NonFungibleToken from "./flow-nft/NonFungibleToken.cdc"
import MetadataViews from "./flow-nft/MetadataViews.cdc"
import FungibleToken from "./flow-ft/FungibleToken.cdc"

pub contract DEmpire {

    pub let EmpireStoragePath: StoragePath
    pub let EmpirePublicRefPath: PublicPath
    pub let EmpirePrivateRefPath: PrivatePath
    pub var currentEmpireId: UInt256;
    pub var empireAccountMap: {UInt256: Address};
    pub var empireAccountRecord: {Address: UInt256};

    pub event EmpireStarted(account: Address)

    pub resource interface EmpireBuildings {
        pub let buildingsPosition : {UInt: [[Fix64]] }
    }

    pub resource interface EmpireUpdate {
        pub fun saveBuildingPositions(assetCollection: @DEAssets.Collection, data: {UInt: [[Fix64]] }): @DEAssets.Collection
    }

    pub resource Empire : EmpireBuildings, EmpireUpdate { 
        pub let buildingsPosition : {UInt: [[Fix64]] }
        pub let ownerAddress: Address
        init(ownerAddress: Address){
            self.buildingsPosition = {}
            self.ownerAddress = ownerAddress
        }

        pub fun saveBuildingPositions(assetCollection: @DEAssets.Collection, data: {UInt: [[Fix64]] }): @DEAssets.Collection{
            let assetTypes = data.keys
            for asset in assetTypes {
                let positions = data[asset]!
                assetCollection.updateLockedAssets(typeId: asset, count: UInt64(positions.length))
                //DEAssets.lockAsset(acc:  acc, typeId: asset, count: UInt64(positions.length))
                self.buildingsPosition[asset] = positions
            }
            return  <- assetCollection
        }
    }

    // currently this functions is getting called from client and no context of fight given
    // In future there will be fight resource and oralce/trusted party which will call this function
    pub fun endFight(buildingDestroyed: UInt64, troopsDestroyed: UInt64, myAddress: Address, opponentAddress: Address){
        let myacc = getAccount(myAddress)
        let refToken = myacc.getCapability<&DEToken.Vault{FungibleToken.Receiver}>(DEToken.ReceiverPublicPath)
        if !refToken.check(){
            panic("No capablity found in your account to receive token!")
        }
        DEToken.faucet(receiver: refToken.borrow()!, amount: UFix64(buildingDestroyed * UInt64(50)))


        let oppacc = getAccount(opponentAddress)
        let refToken1 = oppacc.getCapability<&DEToken.Vault{FungibleToken.Receiver}>(DEToken.ReceiverPublicPath)
        if refToken1.check(){
            DEToken.faucet(receiver: refToken1.borrow()!, amount: UFix64(troopsDestroyed * UInt64(15)))
        }
    }

    init() {
        self.EmpireStoragePath = /storage/Empire
        self.EmpirePublicRefPath = /public/EmpireRef
        self.EmpirePrivateRefPath = /private/EmpireRef
        self.currentEmpireId = 0
        self.empireAccountMap = {}
        self.empireAccountRecord = {}
    }

    pub fun startGame(user: Address) : @Empire {
        pre{
            self.empireAccountRecord[user] == nil : "Game Already Started!"
        }
        post{
            self.currentEmpireId == before(self.currentEmpireId) + 1:
            "empire id is not incremented by one"
        }
        let newEmpire <- create Empire(ownerAddress: user)
        // only for testnet
        let acc = getAccount(user)
        let refAsset = acc.getCapability<&DEAssets.Collection{NonFungibleToken.CollectionPublic, DEAssets.DEAssetsCollectionPublic, MetadataViews.ResolverCollection}>(DEAssets.CollectionPublicPath)
        if !refAsset.check(){
            panic("No capablity found to receive asset!")
        }

        let refToken = acc.getCapability<&DEToken.Vault{FungibleToken.Receiver}>(DEToken.ReceiverPublicPath)
        if !refToken.check(){
            panic("No capablity found to receive token!")
        }

        DEToken.faucet(receiver: refToken.borrow()!, amount: 1000.0)
        DEAssets.mintTownHall(recipient: refAsset.borrow()!)

        self.empireAccountMap[self.currentEmpireId] = user
        self.empireAccountRecord[user] = self.currentEmpireId
        self.currentEmpireId = self.currentEmpireId + 1
        //acc.save<@Empire>(<-newEmpire, to: self.EmpireStoragePath)
        //acc.link<&Empire{EmpireUpdate}>(self.EmpirePrivateRefPath, target: self.EmpireStoragePath)
        //acc.link<&Empire{EmpireBuildings}>(self.EmpirePublicRefPath, target: self.EmpireStoragePath)
        emit EmpireStarted(account: acc.address)
        return <- newEmpire
    }
}
 