import NonFungibleToken from "./flow-nft/NonFungibleToken.cdc"
import MetadataViews from "./flow-nft/MetadataViews.cdc"
import DEToken from "./DEToken.cdc"

pub contract DEAssets: NonFungibleToken {

    /// Total supply of DEAssetss in existence
    pub var totalSupply: UInt64

    /// The event that is emitted when the contract is created
    pub event ContractInitialized()

    /// The event that is emitted when an NFT is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)

    /// The event that is emitted when an NFT is deposited to a Collection
    pub event Deposit(id: UInt64, to: Address?)

    /// Storage and Public Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    //pub let MinterStoragePath: StoragePath
    
    pub struct Asset {
        pub let typeId: UInt
        pub let name: String
        pub let description: String
        pub let price: UFix64
        pub let useDEToken: Bool
        pub let thumbnail: String  
        init(typeId: UInt, name: String, description: String, price: UFix64, useDEToken: Bool, thumbnail: String){
            self.name = name
            self.typeId = typeId
            self.description = description
            self.price = price
            self.useDEToken = useDEToken
            self.thumbnail = thumbnail
        }
    }

    pub let nftTypeMappping: {UInt: Asset}
    /// The core resource that represents a Non Fungible Token. 
    /// New instances will be created using the NFTMinter resource
    /// and stored in the Collection resource
    ///
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        
        /// The unique ID that each NFT has
        pub let id: UInt64
        pub let typeId: UInt

        /// Metadata fields
        pub let name: String
        pub let description: String
        pub let thumbnail: String

        access(self) let royalties: [MetadataViews.Royalty]
        access(self) let metadata: {String: AnyStruct}
    
        init(
            typeId: UInt,
            id: UInt64,
            name: String,
            description: String,
            thumbnail: String,
            royalties: [MetadataViews.Royalty],
            metadata: {String: AnyStruct},
        ) {
            self.typeId = typeId
            self.id = id
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.royalties = royalties
            self.metadata = metadata
        }

        /// Function that returns all the Metadata Views implemented by a Non Fungible Token
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        /// Function that resolves a metadata view for this token.
        ///
        /// @param view: The Type of the desired view.
        /// @return A structure representing the requested view.
        ///
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
                case Type<MetadataViews.Editions>():
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "DEmpire Level-1", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://dempire-assets.b-cdn.net/".concat(self.typeId.toString()).concat(".jpeg"))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: DEAssets.CollectionStoragePath,
                        publicPath: DEAssets.CollectionPublicPath,
                        providerPath: /private/DEAssetsCollection,
                        publicCollection: Type<&DEAssets.Collection{DEAssets.DEAssetsCollectionPublic}>(),
                        publicLinkedType: Type<&DEAssets.Collection{DEAssets.DEAssetsCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&DEAssets.Collection{DEAssets.DEAssetsCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-DEAssets.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://dempire-assets.b-cdn.net/townhall.jpeg"
                        ),
                        mediaType: "image/jpeg"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "DEmpire",
                        description: "In game assets of DEmpire.",
                        externalURL: MetadataViews.ExternalURL("https://dempire-assets.b-cdn.net/dempire.apk"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {}
                    )
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime and foo to show other uses of Traits
                    let excludedTraits = ["mintedTime"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

                    // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)
                    
                    return traitsView

            }
            return nil
        }
    }

    /// Defines the methods that are particular to this NFT contract collection
    ///
    pub resource interface DEAssetsCollectionPublic {
        pub let availableAssets : {UInt: UInt64}
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowDEAssets(id: UInt64): &DEAssets.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow DEAssets reference: the ID of the returned reference is incorrect"
            }
        }
    }

    /// The resource that will be holding the NFTs inside any account.
    /// In order to be able to manage NFTs any account will need to create
    /// an empty collection first
    ///
    pub resource Collection: DEAssetsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        access(contract) let lockedAssets :{UInt: UInt64}
        pub let availableAssets : {UInt: UInt64}

        init () {
            self.ownedNFTs <- {}
            self.lockedAssets = {}
            self.availableAssets = {}
        }

        /// Removes an NFT from the collection and moves it to the caller
        ///
        /// @param withdrawID: The ID of the NFT that wants to be withdrawn
        /// @return The NFT resource that has been taken out of the collection
        ///
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID)  ?? panic("missing NFT") 
            let _token <- token as!  @DEAssets.NFT
            let count = self.availableAssets[_token.typeId]!
            if count <= 0{
                panic("No asset available to withdraw!")
            }
            self.availableAssets[_token.typeId] = count - 1
            emit Withdraw(id: _token.id, from: self.owner?.address)
            return <-_token
        }

        access(contract) fun updateLockedAssets(typeId: UInt, count: UInt64){
            self.lockedAssets[typeId] = count
        }

        access(contract) fun updateAvailableAssets(typeId: UInt, count: UInt64){
            self.availableAssets[typeId] = count
        }

        /// Adds an NFT to the collections dictionary and adds the ID to the id array
        ///
        /// @param token: The NFT resource to be included in the collection
        /// 
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @DEAssets.NFT

            let id: UInt64 = token.id
            let typeId = token.typeId
            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token
            if oldToken == nil{
                var oldCount = UInt64(0) 
                if self.availableAssets[typeId] != nil{
                    oldCount = self.availableAssets[typeId]!
                }
                self.availableAssets[typeId] = oldCount + 1
            }
            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        /// Helper method for getting the collection IDs
        ///
        /// @return An array containing the IDs of the NFTs in the collection
        ///
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Gets a reference to an NFT in the collection so that 
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
 
        /// Gets a reference to an NFT in the collection so that 
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///        
        pub fun borrowDEAssets(id: UInt64): &DEAssets.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &DEAssets.NFT
            }

            return nil
        }

        /// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
        /// interface so that the caller can retrieve the views that the NFT
        /// is implementing and resolve them
        ///
        /// @param id: The ID of the wanted NFT
        /// @return The resource reference conforming to the Resolver interface
        /// 
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let DEAssets = nft as! &DEAssets.NFT
            return DEAssets as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    /// Allows anyone to create a new empty collection
    ///
    /// @return The new Collection resource
    ///
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    /// Resource that an admin or something similar would own to be
    /// able to mint new NFTs
    ///
    access(self) fun mintNFT(
        typeId: UInt,
        recipient: &{NonFungibleToken.CollectionPublic},
        name: String,
        description: String,
        thumbnail: String
    ) {
        let metadata: {String: AnyStruct} = {}
        let currentBlock = getCurrentBlock()
        metadata["mintedBlock"] = currentBlock.height
        metadata["mintedTime"] = currentBlock.timestamp
        metadata["minter"] = recipient.owner!.address

        // create a new NFT
        var newNFT <- create NFT(
            typeId: typeId, 
            id: DEAssets.totalSupply,
            name: name,
            description: description,
            thumbnail: thumbnail,
            royalties: [],
            metadata: metadata,
        )

        // deposit it in the recipient's account using their reference
        recipient.deposit(token: <-newNFT)

        DEAssets.totalSupply = DEAssets.totalSupply + UInt64(1)
    }

    access(account) fun lockAsset(acc: AuthAccount, typeId: UInt, count: UInt64){
        let collection <- acc.load<@Collection>(from: self.CollectionStoragePath) ?? panic("collection not found")
        let lockedAssets = collection.lockedAssets!
        let availableAssets = collection.availableAssets!
        var lockedTypeCount = UInt64(0)
        var availabeTypeCount = UInt64(0)
        if lockedAssets[typeId] != nil {
            lockedTypeCount = lockedAssets[typeId]!
        }
        if availableAssets[typeId] != nil {
            availabeTypeCount = availableAssets[typeId]!
        }
        if (availabeTypeCount + lockedTypeCount) - count < 0{
            panic("Locking assets more thne you own!")
        }
        availabeTypeCount = (availabeTypeCount + lockedTypeCount) - count
        lockedTypeCount = count
        collection.updateLockedAssets(typeId: typeId, count: lockedTypeCount)
        collection.updateAvailableAssets(typeId: typeId, count: availabeTypeCount)
        acc.save(<- collection, to: self.CollectionStoragePath)
    }

    access(account) fun unLockAsset(acc: AuthAccount, typeId: UInt, count: UInt64){
        let collection <- acc.load<@Collection>(from: self.CollectionStoragePath) ?? panic("collection not found")
        let lockedAssets = collection.lockedAssets!
        let availableAssets = collection.availableAssets!
        var lockedTypeCount = UInt64(0)
        var availabeTypeCount = UInt64(0)
        if lockedAssets[typeId] != nil {
            lockedTypeCount = lockedAssets[typeId]!
        }
        if availableAssets[typeId] != nil {
            availabeTypeCount = availableAssets[typeId]!
        }
        if (availabeTypeCount + lockedTypeCount) - count < 0{
            panic("unLocking assets more then you own!")
        }
        lockedTypeCount = (availabeTypeCount + lockedTypeCount) - count
        availabeTypeCount = count
        collection.updateLockedAssets(typeId: typeId, count: lockedTypeCount)
        collection.updateAvailableAssets(typeId: typeId, count: availabeTypeCount)
        acc.save(<- collection, to: self.CollectionStoragePath)
    }

    access(account) fun mintTownHall(acc: AuthAccount){
        let asset = self.nftTypeMappping[0] ?? panic("Asset type not found")
        let isCollection =  acc.type(at: self.CollectionStoragePath)
        if isCollection == nil{
            let collection <- create Collection()
            acc.save(<-collection, to: self.CollectionStoragePath)
        }
        var ref = acc.getCapability<&DEAssets.Collection{NonFungibleToken.CollectionPublic, DEAssets.DEAssetsCollectionPublic, MetadataViews.ResolverCollection}>(self.CollectionPublicPath)
        if !ref.check(){
            acc.link<&DEAssets.Collection{NonFungibleToken.CollectionPublic, DEAssets.DEAssetsCollectionPublic, MetadataViews.ResolverCollection}>(
                self.CollectionPublicPath,
                target: self.CollectionStoragePath
            )
            ref = acc.getCapability<&DEAssets.Collection{NonFungibleToken.CollectionPublic, DEAssets.DEAssetsCollectionPublic, MetadataViews.ResolverCollection}>(self.CollectionPublicPath)
        }
        self.mintNFT(typeId: 0, recipient: ref.borrow()! , name: asset.name, description: asset.description, thumbnail: asset.thumbnail)
    }

    pub fun buy(acc: AuthAccount, typeId: UInt){
        pre{
            typeId !=0: "You can't buy townhall!"
        }
        let asset = self.nftTypeMappping[typeId] ?? panic("Asset type not found")
        if asset.useDEToken {
            DEToken.spend(acc: acc, amount: asset.price)
        }
        let isCollection =  acc.type(at: self.CollectionStoragePath)
        if isCollection == nil{
            let collection <- create Collection()
            acc.save(<-collection, to: self.CollectionStoragePath)
        }
        var ref = acc.getCapability<&DEAssets.Collection{NonFungibleToken.CollectionPublic, DEAssets.DEAssetsCollectionPublic, MetadataViews.ResolverCollection}>(self.CollectionPublicPath)
        if !ref.check(){
            acc.link<&DEAssets.Collection{NonFungibleToken.CollectionPublic, DEAssets.DEAssetsCollectionPublic, MetadataViews.ResolverCollection}>(
                self.CollectionPublicPath,
                target: self.CollectionStoragePath
            )
            ref = acc.getCapability<&DEAssets.Collection{NonFungibleToken.CollectionPublic, DEAssets.DEAssetsCollectionPublic, MetadataViews.ResolverCollection}>(self.CollectionPublicPath)
        }
        self.mintNFT(typeId: typeId, recipient: ref.borrow()! , name: asset.name, description: asset.description, thumbnail: asset.thumbnail)
    }

    init() {
        self.nftTypeMappping = {
            0: Asset(typeId: 0, name: "TownHall", description: "HQ of your empire.", price: 0.0, useDEToken: false, thumbnail: "https://dempire-assets.b-cdn.net/0.jpeg"),
            1: Asset(typeId: 1, name: "Miner", description: "Miner mines DEToken at certain interval", price: 60.0, useDEToken: true, thumbnail: "https://dempire-assets.b-cdn.net/1.jpeg"),
            2: Asset(typeId: 2, name: "Canon", description: "It's powefull canon machine which attacks enemy", price: 250.0, useDEToken: true, thumbnail: "https://dempire-assets.b-cdn.net/2.jpeg"),
            3: Asset(typeId: 3, name: "Xbow", description: "It's building which having bow machine which attacks enemy with arrow", price: 150.0, useDEToken: true, thumbnail: "https://dempire-assets.b-cdn.net/3.jpeg"),
            4: Asset(typeId: 4, name: "Tesla", description: "Its tesla tower which generates magnatic waves to attack on enemy.", price: 180.0, useDEToken: true, thumbnail: "https://dempire-assets.b-cdn.net/4.jpeg"),
            5: Asset(typeId: 5, name: "Archer", description: "Archer is attacker which attacks with bow and arrow", price: 50.0, useDEToken: true, thumbnail: "https://dempire-assets.b-cdn.net/5.png"),
            6: Asset(typeId: 6, name: "Robot", description: "It's robot which drill downs the buildings", price: 75.0, useDEToken: true, thumbnail: "https://dempire-assets.b-cdn.net/6.png"),
            7: Asset(typeId: 7, name: "Valkyriee", description: "It's fast, smart and powerfull attacker which attacks with the gun", price: 80.0, useDEToken: true, thumbnail: "https://dempire-assets.b-cdn.net/7.png")
        }
        // Initialize the total supply
        self.totalSupply = 0

        // Set the named paths
        self.CollectionStoragePath = /storage/DEAssetsCollection
        self.CollectionPublicPath = /public/DEAssetsCollection

        emit ContractInitialized()
    }
}
