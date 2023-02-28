package com.ob.flow

import android.os.Debug
import android.util.Log
import com.nftco.flow.sdk.cadence.*
import kotlin.random.Random
import io.outblock.fcl.Fcl
import io.outblock.fcl.FlowEnvironment
import io.outblock.fcl.FlowNetwork
import io.outblock.fcl.config.AppMetadata
import io.outblock.fcl.models.FclResult
import io.outblock.fcl.provider.WalletProvider
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import com.unity3d.player.UnityPlayer;
import io.outblock.fcl.models.toFclArgument
import io.outblock.fcl.strategies.walletconnect.WalletConnectMeta
import org.json.JSONArray
import org.json.JSONObject
import java.util.*


class dempire {

    var address: String = "";
    var opponnetAddress = "";
    var buildingsPositon = "";
    var townhall_ = 0;
    var miner_ = 0;
    var cannon_ = 0;
    var xbow_ = 0;
    var tesla_ = 0;
    var coins_ = 0;
    var archer_ = 0;
    var robot_ = 0;
    var valkyriee_ = 0;


    public fun getTownhall() :Int{
        return  townhall_
    }

    public fun getMiner() :Int{
        return  miner_
    }

    public fun getCannon() :Int{
        return  cannon_
    }

    public fun getXbow() :Int{
        return  xbow_
    }

    public fun getTesla() :Int{
        return  tesla_
    }

    public fun getCoins() :Int{
        return  coins_
    }

    public fun getArcher() :Int{
        return  archer_
    }

    public fun getRobot() :Int{
        return  robot_
    }

    public fun getValkyriee() :Int{
        return  valkyriee_
    }

    fun setup(){
        val environment = FlowEnvironment(
            network = FlowNetwork.TESTNET,
            addressRegistry = listOf(
                Pair("0xDEmpire", "0xd266971344d1a1ed"),
                Pair("0xDEToken", "0xd266971344d1a1ed"),
                Pair("0xDEAssets", "0xd266971344d1a1ed"),
                Pair("0xFungibleToken", "0xd266971344d1a1ed")
            )
        )

        val appMetadata = AppMetadata(
            appName = "DEmpire",
            appIcon = "https://dempire-assets.b-cdn.net/icon.png",
            location = "https://dempire.game",
            appId = "v0.0",
            nonce = "75f8587e5bd5f9dcc9909d0dae1f0ac5814458b2ae129620502cb936fde7120a",
        )

        val walletConnectMeta = WalletConnectMeta(
            projectId = "29b38ec12be4bd19bf03d7ccef29aaa6",
            name = "DEmpire",
            description = "Mobile base RTS game on flow",
            url = "https://link.lilico.app",
            icon = "https://lilico.app/logo.png",
        )

        Fcl.config(
            appMetadata = appMetadata,
            env = environment,
            walletConnectMeta = walletConnectMeta
        )
    }

    public  fun parseBuldingData(posVal: String): String{
        val output = JSONObject()
        output.put("address","")
        val buil = mutableListOf<JSONObject>()
        val data = JSONObject(posVal)
        val kvArrayy = data.getJSONArray("value")
        for(kv in 0 until kvArrayy.length()){
            val obj = kvArrayy.getJSONObject(kv)
            val key = obj.getJSONObject("key").getString("value").toInt()
            val values = obj.getJSONObject("value").getJSONArray("value")
            Log.d("DEmpire-kt", values.toString())
            for(varray in 0 until values.length()){
                val posData = values.getJSONObject(varray).getJSONArray("value")
                val x = posData.getJSONObject(0).getString("value").toDouble()
                val y = posData.getJSONObject(1).getString("value").toDouble()
                val z = posData.getJSONObject(2).getString("value").toDouble()
                val rotation = posData.getJSONObject(3).getString("value").toDouble()
                val o = JSONObject()
                o.put("buildingIndex", key)
                o.put("rotation", rotation)
                o.put("position", JSONArray(arrayOf(x, y, z)))
                buil.add(o)
            }
        }
        output.put("buil", JSONArray(buil))
        return output.toString()
    }

    public fun connect(provider: String){
        val wp: WalletProvider;
        when (provider) {
            "DAPPER" -> wp = WalletProvider.DAPPER
            "LILICO" -> wp = WalletProvider.LILICO
            else -> { // Note the block
                wp = WalletProvider.BLOCTO;
            }
        }
        CoroutineScope(Dispatchers.IO).launch {
            when (val result = Fcl.authenticate(wp)) {
                is FclResult.Success -> CoroutineScope(Dispatchers.Main).launch {
                    result.value.data?.address?.let {
                        Log.d("DEmpire-kt", it)
                        address = it;
                        UnityPlayer.UnitySendMessage("RTS_Camera","onConnect","");
                    };
                }
                is FclResult.Failure -> result.throwable.message?.let { Log.e("DEmpire-kt: connect", it) };
            }
        }
    }

    public fun NewUserCheck(){
        CoroutineScope(Dispatchers.IO).launch {
            val cadence = """
                import DEmpire from 0xDEmpire
                
                pub fun main(acc: Address): {UInt: [[Fix64]]}? {
                    let publicAcc = getAccount(acc)
                    var ref = publicAcc.getCapability<&DEmpire.Empire{DEmpire.EmpireBuildings}>(DEmpire.EmpirePublicRefPath)
                    if ref.check(){
                        let borrowdRef = ref.borrow()!
                        return borrowdRef.buildingsPosition
                    }
                    return nil
                }
            """.trimIndent()
            Log.d("DEmpire-kt", cadence);
            val result = Fcl.query {
                cadence(cadence)
                arg {  address(address) }
            }
            when (result) {
                is FclResult.Success -> CoroutineScope(Dispatchers.Main).launch {
                    Log.d("DEmpire-kt", result.value)
                    try{
                        val jsonObject = JSONObject(result.value)
                        val value = jsonObject.get("value") // value will be null
                        if (value.equals(null)) {
                            buildingsPositon = "{\"address\":\"\", \"buil\":[] }"
                            UnityPlayer.UnitySendMessage("RTS_Camera","onNewUser","");
                        } else {
                            Log.d("DEmpire-kt", value.toString());
                            buildingsPositon = parseBuldingData(value.toString())
                            Log.d("DEmpire-kt", buildingsPositon);
                            updateData();
                            updateCoin();
                        }
                    }catch (e: Exception){
                        Log.e("DEmpire-kt: NewUserCheck", e.toString())
                    }
                }
                is FclResult.Failure -> result.throwable.message?.let { Log.e("DEmpire-kt: NewUserCheck", it) };
            }
        }
    }

    public fun endGame(buildingCount:Int, troopsCount: Int){
        CoroutineScope(Dispatchers.IO).launch {
            val cadence = """
                import DEmpire from 0xd266971344d1a1ed
                
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
            """.trimIndent()

            val result = Fcl.mutate {
                cadence(cadence)
                arg{ UInt64NumberField(buildingCount.toString()) }
                arg{ UInt64NumberField(troopsCount.toString()) }
                arg{ address(opponnetAddress) }
                gasLimit(1000)
            }

            when (result) {
                is FclResult.Success -> CoroutineScope(Dispatchers.Main).launch {
                    Log.d("DEmpire-kt", "tid:$result")
                    UnityPlayer.UnitySendMessage("Button_AD", "showData", "")
                }
                is FclResult.Failure -> result.throwable.message?.let { Log.e("DEmpire-kt: endGame", it) };
            }
        }
    }

    public fun saveGame(data: String){
        try{
            val jsonObject = JSONObject(data)
            val townhall = mutableListOf<Array<String>>()
            val miner = mutableListOf<Array<String>>()
            val cannon = mutableListOf<Array<String>>()
            val xbow = mutableListOf<Array<String>>()
            val tesla = mutableListOf<Array<String>>()
            val buildings: JSONArray = jsonObject.getJSONArray("buil")
            for (i in 0 until buildings.length()) {
                val element = buildings.getJSONObject(i)
                val buldingIndex = element.getInt("buildingIndex")
                val rotation = String.format("%.2f",element.getDouble("rotation"))
                val position = element.getJSONArray("position")
                val x = String.format("%.2f",position.getDouble(0))
                val y = String.format("%.2f",position.getDouble(1))
                val z = String.format("%.2f",position.getDouble(2))
                val d = arrayOf( "Fix64("+x+")",  "Fix64("+y+")",  "Fix64("+z+")",  "Fix64("+rotation+")")
                if(buldingIndex == 0){
                    townhall.add(d)
                }else if(buldingIndex==1){
                    miner.add(d)
                }else if(buldingIndex==2){
                    cannon.add(d)
                }else if(buldingIndex==3){
                    xbow.add(d)
                }else if(buldingIndex==4){
                    tesla.add(d)
                }
            }
            val obj = JSONObject()
            obj.put("0", JSONArray(townhall))
            obj.put("1", JSONArray(miner))
            obj.put("2", JSONArray(cannon))
            obj.put("3", JSONArray(xbow))
            obj.put("4", JSONArray(tesla))

            val data = obj.toString().replace("\"","")
            Log.d("DEmpire-kt", data)

            /*val townhall_ = DictionaryField(arrayOf())
            val miner_ = ArrayField(miner.toTypedArray())
            val cannon_ = ArrayField(cannon.toTypedArray())
            val xbow_ = ArrayField(xbow.toTypedArray())
            val tesla_ = ArrayField(tesla.toTypedArray())

            val townhall__ = DictionaryFieldEntry(key=UIntNumberField("0"), value = townhall_  )
            val miner__ = DictionaryFieldEntry(key=UIntNumberField("1"), value = miner_  )
            val cannon__ = DictionaryFieldEntry(key=UIntNumberField("2"), value = cannon_  )
            val xbow__ = DictionaryFieldEntry(key=UIntNumberField("3"), value = xbow_  )
            val tesla__ = DictionaryFieldEntry(key=UIntNumberField("4"), value = tesla_  )

            val data = DictionaryField(arrayOf(townhall__, miner__, cannon__, xbow__, tesla__))*/

            CoroutineScope(Dispatchers.IO).launch {
                val cadence = """
                 import DEmpire from 0xd266971344d1a1ed
                 import DEAssets from 0xd266971344d1a1ed
                  
                 transaction { 
                  let acc: AuthAccount 
                  
                  prepare(signer: AuthAccount) { 
                   self.acc = signer  
                  } 
                  
                  pre {} 
                  
                  execute { 
                   let collection <- self.acc.load<@DEAssets.Collection>(from: DEAssets.CollectionStoragePath) ?? panic("collection not found") 
                   let ref = self.acc.getCapability<&DEmpire.Empire{DEmpire.EmpireUpdate}>(DEmpire.EmpirePrivateRefPath) 
                   if ref.check() { 
                    let borrowdRef = ref.borrow()! 
                    let updatedCollection <- borrowdRef.saveBuildingPositions(assetCollection: <-collection, data: $data)
                    self.acc.save(<-updatedCollection, to: DEAssets.CollectionStoragePath) 
                   }else{ 
                    panic("private reference to empire not found") 
                   } 
                  } 
                  
                  post {} 
                 }
            """.trimIndent()

                val result = Fcl.mutate {
                    cadence(cadence)
                    gasLimit(1000)
                }

                when (result) {
                    is FclResult.Success -> CoroutineScope(Dispatchers.Main).launch {
                        Log.d("DEmpire-kt", "tid:$result")
                        UnityPlayer.UnitySendMessage("syncButton", "onSave", "")
                    }
                    is FclResult.Failure -> result.throwable.message?.let { Log.e("DEmpire-kt: startGame", it) };
                }
            }

        }catch (e: Exception){
            Log.e("DEmpire-kt: saveGame", e.toString())
        }
    }

    public fun getBuildingData(): String{
        return buildingsPositon;
    }

    public fun updateCoin(){
        val timer = Timer()
        timer.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                CoroutineScope(Dispatchers.IO).launch {
                    val cadence = """
                        import DEToken from 0xDEToken
                        import FungibleToken from 0xFungibleToken 
                        
                        pub fun main(acc: Address): UFix64? {
                            let publicAcc = getAccount(acc)
                            var ref = publicAcc.getCapability<&DEToken.Vault{FungibleToken.Balance}>(DEToken.VaultPublicPath)
                            if ref.check() {
                                let borrowdRef = ref.borrow()!
                                return borrowdRef.balance
                            }
                            return nil
                        }
                    """.trimIndent()
                    Log.d("DEmpire-kt", cadence);
                    val result = Fcl.query {
                        cadence(cadence)
                        arg { address(address) }
                    }
                    when (result) {
                        is FclResult.Success -> CoroutineScope(Dispatchers.Main).launch {
                            Log.d("DEmpire-kt", result.value);
                            try{
                                val jsonObject = JSONObject(result.value)
                                val value = jsonObject.getJSONObject("value").getString("value") // value will be null
                                if (!value.equals(null)) {
                                    Log.d("DEmpire-kt", value.toString());
                                    coins_ = value.substring(0, value.indexOf(".")).toInt()
                                }
                            }catch (e: Exception){
                                Log.e("DEmpire-kt: updateData", e.toString())
                            }
                        }
                        is FclResult.Failure -> result.throwable.message?.let { Log.e("DEmpire-kt: updateCoin", it) };
                    }
                }
            }
        }, 0, 5000)
    }

    public fun updateData(){
        val timer = Timer()
        timer.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                CoroutineScope(Dispatchers.IO).launch {
                    val cadence = """
                        import DEAssets from 0xDEAssets
                        
                        pub fun main(acc: Address): {UInt: UInt64}? {
                            let publicAcc = getAccount(acc)
                            var ref = publicAcc.getCapability<&DEAssets.Collection{DEAssets.DEAssetsCollectionPublic}>(DEAssets.CollectionPublicPath)
                            if ref.check()  {
                                let borrowdRef = ref.borrow()!
                                return borrowdRef.availableAssets
                            }
                            return nil
                        }
                    """.trimIndent()
                    Log.d("DEmpire-kt", cadence);
                    val result = Fcl.query {
                        cadence(cadence)
                        arg { address(address) }
                    }
                    when (result) {
                        is FclResult.Success -> CoroutineScope(Dispatchers.Main).launch {
                            Log.d("DEmpire-kt", result.value);
                            try{
                                val jsonObject = JSONObject(result.value)
                                val value = jsonObject.getJSONObject("value").getJSONArray("value") // value will be null
                                if (!value.equals(null)) {
                                    for(kv in 0 until value.length()){
                                        val key = value.getJSONObject(kv).getJSONObject("key").getString("value").toInt()
                                        val valu = value.getJSONObject(kv).getJSONObject("value").getString("value").toInt()
                                        if(key ==0){
                                            townhall_ = valu
                                        }else if(key==1){
                                            miner_ = valu
                                        }else if(key==2){
                                            cannon_ = valu
                                        }else if(key==3){
                                            xbow_ = valu
                                        }else if(key==4){
                                            tesla_ = valu
                                        }else if(key==5){
                                            archer_ = valu
                                        }else if(key==6){
                                            robot_ = valu
                                        }else if(key==7){
                                            valkyriee_ = valu
                                        }
                                    }
                                    UnityPlayer.UnitySendMessage("RTS_Camera","onDone","");
                                }
                            }catch (e: Exception){
                                Log.e("DEmpire-kt: updateData", e.toString())
                            }
                        }
                        is FclResult.Failure -> result.throwable.message?.let { Log.e("DEmpire-kt: updateData", it) };
                    }
                }
            }
        }, 0, 5000)
    }

    public fun getWalletAddress(): String{
        return address;
    }

    public fun startWar(){
        CoroutineScope(Dispatchers.IO).launch {
            val cadence = """
                import DEmpire from 0xDEmpire
                
                pub fun main(acc: Address): {UInt: [[Fix64]]}? {
                    let publicAcc = getAccount(acc)
                    var ref = publicAcc.getCapability<&DEmpire.Empire{DEmpire.EmpireBuildings}>(DEmpire.EmpirePublicRefPath)
                    if ref.check(){
                        let borrowdRef = ref.borrow()!
                        return borrowdRef.buildingsPosition
                    }
                    return nil
                }
            """.trimIndent()
            Log.d("DEmpire-kt", cadence);
            val result = Fcl.query {
                cadence(cadence)
                arg {  address(opponnetAddress) }
            }
            when (result) {
                is FclResult.Success -> CoroutineScope(Dispatchers.Main).launch {
                    Log.d("DEmpire-kt", result.value)
                    try{
                        val jsonObject = JSONObject(result.value)
                        val value = jsonObject.get("value") // value will be null
                        UnityPlayer.UnitySendMessage("WarManager","onWarData", parseBuldingData(value.toString()))
                    }catch (e: Exception){
                        Log.e("DEmpire-kt: startWar", e.toString())
                    }
                }
                is FclResult.Failure -> result.throwable.message?.let { Log.e("DEmpire-kt: startWar", it) };
            }
        }
    }

    public fun setRandomOpponent(total: Int){
        val target =  Random.nextInt(0, total)
        CoroutineScope(Dispatchers.IO).launch {
            val cadence = """
                    import DEmpire from 0xDEmpire
                    
                    pub fun main(empireId: UInt256): Address? {
                        return DEmpire.empireAccountMap[empireId] 
                    }
            """.trimIndent()
            Log.d("DEmpire-kt", cadence);
            val result = Fcl.query {
                cadence(cadence)
                arg{ UInt256NumberField(target.toString()) }
            }
            when (result) {
                is FclResult.Success -> CoroutineScope(Dispatchers.Main).launch {
                    Log.d("DEmpire-kt", result.value);
                    try {
                        val oppoadd = JSONObject(result.value).getJSONObject("value").getString("value")
                        if(oppoadd != address){
                            opponnetAddress = oppoadd
                            startWar()
                        }else{
                            Log.d("DEmpire-kt", "own address as opponent")
                            setRandomOpponent(total)
                        }
                    } catch (e: Exception) {
                        Log.e("DEmpire-kt: setRandomOpponent", e.toString())
                        setRandomOpponent(total)
                    }
                }
                is FclResult.Failure -> result.throwable.message?.let {
                    Log.e("DEmpire-kt: setRandomOpponent", it)
                };
            }
        }
    }

    public fun prepareWarDate() {
        CoroutineScope(Dispatchers.IO).launch {
            val cadence = """
                    import DEmpire from 0xDEmpire
                    
                    pub fun main(): UInt256 {
                        return DEmpire.currentEmpireId 
                    }
            """.trimIndent()
            Log.d("DEmpire-kt", cadence);
            val result = Fcl.query {
                cadence(cadence)
            }
            when (result) {
                is FclResult.Success -> CoroutineScope(Dispatchers.Main).launch {
                    Log.d("DEmpire-kt", result.value);
                    try {
                        val count = JSONObject(result.value).getString("value").toInt()
                        setRandomOpponent(count)
                    } catch (e: Exception) {
                        Log.e("DEmpire-kt: prepareWarDate", e.toString())
                    }
                }
                is FclResult.Failure -> result.throwable.message?.let {
                    Log.e("DEmpire-kt: prepareWarDate", it)
                };
            }
        }
    }

    public fun buy(typeId: Int){
        CoroutineScope(Dispatchers.IO).launch {
            val cadence = """
                import DEmpire from 0xd266971344d1a1ed
                import DEAssets from 0xd266971344d1a1ed
                import DEToken from 0xd266971344d1a1ed
                import NonFungibleToken from 0xd266971344d1a1ed
                import MetadataViews from 0xd266971344d1a1ed
                import FungibleToken from 0xd266971344d1a1ed
                
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
            """.trimIndent()
            var amounts = arrayOf(0.00, 60.00, 250.00, 150.00, 180.00, 50.00, 75.00, 80.00)

            val result = Fcl.mutate {
                cadence(cadence)
                arg { UIntNumberField(typeId.toString()) }
                arg { UFix64NumberField(amounts[typeId].toString()) }
                gasLimit(1000)
            }

            when (result) {
                is FclResult.Success -> CoroutineScope(Dispatchers.Main).launch {
                    Log.d("DEmpire-kt", "tid:$result")
                }
                is FclResult.Failure -> result.throwable.message?.let { Log.e("DEmpire-kt: startGame", it) };
            }
        }
    }

    public fun startGame(){
        CoroutineScope(Dispatchers.IO).launch {
            val cadence = """
            import DEmpire from 0xd266971344d1a1ed
            import DEAssets from 0xd266971344d1a1ed
            import DEToken from 0xd266971344d1a1ed
            import NonFungibleToken from 0xd266971344d1a1ed
            import MetadataViews from 0xd266971344d1a1ed
            import FungibleToken from 0xd266971344d1a1ed
            
            transaction {
                let acc: AuthAccount
            
                prepare(signer: AuthAccount) {
                    self.acc = signer
                    let isCollection =  self.acc.type(at: DEAssets.CollectionStoragePath)
                    if(isCollection == nil){
                        let collection <- DEAssets.createEmptyCollection()
                        self.acc.save(<-collection, to: DEAssets.CollectionStoragePath)
                    }
            
                    var ref = self.acc.getCapability<&DEAssets.Collection{NonFungibleToken.CollectionPublic, DEAssets.DEAssetsCollectionPublic, MetadataViews.ResolverCollection}>(DEAssets.CollectionPublicPath)
                    if(!ref.check()){
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
            """.trimIndent()
            val result = Fcl.mutate {
                cadence(cadence)
                gasLimit(1000)
            }

            when (result) {
                is FclResult.Success -> CoroutineScope(Dispatchers.Main).launch {
                    Log.d("DEmpire-kt", "tid:$result")
                    updateData();
                    updateCoin();
                }
                is FclResult.Failure -> result.throwable.message?.let { Log.e("DEmpire-kt: startGame", it) };
            }
        }
    }
}