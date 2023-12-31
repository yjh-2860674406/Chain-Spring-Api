// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Base.sol";

contract TradeManagement is IERC721Receiver {
    //** 三个合约 **//
    Base public RawMaterialSmartContract;
    Base public PackagedProductSmartContract;
    Base public ProductLotSmartContract;
    Base public PackageLotSmartContract;

    // 授权者 -> 合约创建者
    address public FoodAuthority;
    // 供应商
    mapping(address => bool) public Supplier;
    // 生产商
    mapping(address => bool) public Producer;
    // 用户（不区分角色）
    mapping(address => string) public User;
    // 批次TOKEN => 原料TOKEN[]
    mapping(uint256 => uint256[]) Lot2RawMaterials;
    // TOKEN => 成品NFT
    mapping(uint256 => PackagedProductsNFT) internal PackagedProductNFTMapping;
    // TOKEN => 原料NFT
    mapping(uint256 => RawMaterialNFT) internal RawMaterialNFTMapping;
    // TOKEN => 成品批次NFT
    mapping(uint256 => ProductsLotNFT) internal ProductsLotNFTMapping;
    // TOKEN => 包装批次NFT
    mapping(uint256 => PackagedLotNFT) internal PackagedLotNFTMapping;
    // 仓库
    mapping(address => address[]) internal RepositoryMapping;

    // 白名单
    mapping(address => bool) whiteList;

    struct Trade {
        uint256 timestamp;
        address from;
        address to;
        string fromName;
        string toName;
    }

    // 产品NFT
    struct PackagedProductsNFT {
        // 唯一标识，即NFT
        uint256 tokenID;
        // 生产批次ID
        uint256 productLotID;
        // 包装批次ID
        uint256 packageLotID;
        // 是否绑定
        bool isBinding;
        // 所有者 懒加载
        address owner;
        // 所有者姓名 懒加载
        string ownerName;
        // 生产企业 懒加载
        string producerName;
        // 产品名称 懒加载
        string name;
        // 交易对象记录
        Trade[] trade;
    }

    // 打包批次NFT
    struct PackagedLotNFT {
        uint256 tokenID;
        // 包装是否完整
        bool isBinding;
        // 所有者 懒加载
        address owner;
        // 所有者名称 懒加载
        string ownerName;
        // 名称
        string name;
        // 关联产品
        uint256[] products;
    }

    // 生产批次NFT
    struct ProductsLotNFT {
        // 唯一标识，即NFT
        uint256 tokenID;
        // 批号名称(批号)
        string lotName;
        // 生产时间
        uint256 produceTime;
        // 生产企业名称
        string producerName;
        // 产品名称
        string name;
        // 生产原材料
        uint256[] rawMaterials;
        // 关联产品
        uint256[] products;
    }

    // 原材料NFT
    struct RawMaterialNFT {
        // 唯一标识
        uint256 tokenID;
        // 批次ID
        uint256 lotID;
        // 生产时间
        uint256 produceTime;
        // 供应商名称
        string supplierName;
        // 供应时间
        uint256 supplierTime;
        // 生产商名称
        string producerName;
        // 剩余总量
        uint128 totalSum;
        // 原料名称
        string name;
        // 入库批次
        string lotName;
        // 生产成品记录
        uint256[] productLots;
        // 消耗数量记录
        uint128[] resumeLots;
    }

    // 列表查询元素
    struct ListElement {
        uint256 tokenID;
        string name;
        address owner;
        string ownerName;
        uint256 totalSum;
    }

    constructor() {
        FoodAuthority = msg.sender;
        whiteList[msg.sender] = true;
    }

    /** 工具方法 **/

    function compareStrings(string memory a, string memory b)
    internal
    pure
    returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function isEmptyString(string memory s) internal pure returns (bool) {
        return bytes(s).length == 0;
    }

    // 设置批次合约
    function setPackageLotContract(address packageLotAddress)
    public
    onlyFoodAuthority
    {
        PackageLotSmartContract = Base(packageLotAddress);
        PackageLotSmartContract.setTradeManagementSC(address(this));
    }

    function setProductLotContract(address productLotAddress)
    public
    onlyFoodAuthority
    {
        ProductLotSmartContract = Base(productLotAddress);
        ProductLotSmartContract.setTradeManagementSC(address(this));
    }

    // 设置成品合约
    function setPackagedProductsContract(address packagedProductAddress)
    public
    onlyFoodAuthority
    {
        PackagedProductSmartContract = Base(packagedProductAddress);
        PackagedProductSmartContract.setTradeManagementSC(address(this));
    }

    // 设置原材料合约
    function setRawMaterialsContract(address rawMaterialsAddress)
    public
    onlyFoodAuthority
    {
        RawMaterialSmartContract = Base(rawMaterialsAddress);
        RawMaterialSmartContract.setTradeManagementSC(address(this));
    }

    //** Modifiers **//
    // 验证调用者是否为食品安全局
    modifier onlyFoodAuthority() {
        require(
            msg.sender == FoodAuthority,
            "Only the food authority can run this function"
        );
        _;
    }

    // 验证调用者是否为供应商
    function onlySupplier(address user) external view {
        require(
            Supplier[user],
            "Only authorized suppliers are allowed to run this function"
        );
    }

    // 验证调用者是否为生产商
    function onlyProducer(address user) external view {
        require(
            Producer[user],
            "Only authorized producers are allowed to run this function"
        );
    }

    //** Functions **//

    // 均只有合约创建者才能调用

    // 注册供应商
    function RegisterProducer(address _producer, string memory name)
    external
    onlyFoodAuthority
    {
        User[_producer] = name;
        Producer[_producer] = true;
    }

    // 注册生产商
    function RegisterSupplier(address _supplier, string memory name)
    external
    onlyFoodAuthority
    {
        User[_supplier] = name;
        Supplier[_supplier] = true;
    }

    // 注册仓库用户
    function RegisterRepository(address parent, address _repository, string memory name)
    external
    onlyFoodAuthority
    {
        User[_repository] = name;
        RepositoryMapping[parent].push(_repository);
    }

    // 注册消费者
    function RegisterUser(address _customer, string memory name)
    external
    onlyFoodAuthority
    {
        User[_customer] = name;
    }

    // 添加白名单
    function AddWhiteList(address _to) public onlyFoodAuthority {
        whiteList[_to] = true;
    }

    // 移除白名单
    function RemoveWhiteList(address _to) public onlyFoodAuthority {
        whiteList[_to] = false;
    }

    /** 成品业务逻辑 **/

    // 初始化PackagedProductsNFT
    function InitPackagedProductsNFT(
    // 交易发起者
        address from,
    // 产品NFT
        uint256[] memory tokenIDs,
    // 产品名称
        string memory name,
    // 生产批次
        string memory productLot,
    // 原料NFT
        uint256[] memory _childIDs,
    // 消耗量
        uint128[] memory resumes
    ) external {
        // 打包生产批次NFT
        uint256 lotID = ProductLotSmartContract.mint(productLot, "", tokenIDs);

        // 初始化生产批次NFT
        ProductsLotNFT storage productsLotNft = ProductsLotNFTMapping[lotID];
        // 设置TOKENID、生产厂商、生产时间以及生产批次
        productsLotNft.tokenID = lotID;
        productsLotNft.producerName = User[from];
        productsLotNft.produceTime = block.timestamp;
        productsLotNft.lotName = productLot;
        productsLotNft.name = name;

        for (uint256 i = 0; i < tokenIDs.length; i++) {
            // 设置每个产品的NFT
            PackagedProductNFTMapping[tokenIDs[i]].tokenID = tokenIDs[i];
            // 添加产品NFT进生产批次里面
            productsLotNft.products.push(tokenIDs[i]);
        }

        for (uint256 i = 0; i < _childIDs.length; i++) {
            // 添加原料NFT进生产批次里面
            productsLotNft.rawMaterials.push(_childIDs[i]);
            RawMaterialNFT storage nft = RawMaterialNFTMapping[_childIDs[i]];
            // 添加原料的生产记录、原料的消耗量以及扣除总量
            nft.productLots.push(lotID);
            nft.resumeLots.push(resumes[i]);
            nft.totalSum -= resumes[i];
        }
    }

    // 尝试记录PackagedProductsNFT交易过程
    function recordInnerTransfer(
    // 交易接收者
        address to,
    // 产品NFT
        uint256 tokenID
    ) external returns (bool) {
        // 尝试获取商品
        PackagedProductsNFT storage nft = PackagedProductNFTMapping[tokenID];
        Trade memory trade;
        // 获取交易对象名称
        trade.toName = User[to];
        trade.to = to;
        // 如果交易对象存在
        if (trade.to != address(0x0)) {
            // 添加交易对象信息
            trade.from = PackagedProductSmartContract.ownerOf(tokenID);
            trade.fromName = User[trade.from];
            trade.timestamp = block.timestamp;
            // 记录最新所有者、交易对象
            nft.trade.push(trade);
            // 包装中的产品拆开交易，则包装取消打包
            PackagedLotNFTMapping[nft.packageLotID].isBinding = false;
            return true;
        }
        return false;
    }

    struct RMInPP {
        uint256 tokenID;
        string name;
    }

    // 查询PackagedProductsNFT当前的分销信息
    function getPackagedProductsNFT(uint256 tokenID)
    public
    view
    returns (
        bool,
        string memory,
        PackagedProductsNFT memory nft,
        Trade[] memory trades,
        RMInPP[] memory rawMaterials
    )
    {
        // 尝试获取PackagedProductsNFTPackagedProductsNFT
        nft = PackagedProductNFTMapping[tokenID];
        // 如果不存在则取消
        if (nft.tokenID == 0x0) {
            return (
                false,
                "The tokenID is not exist",
                nft,
                trades,
                rawMaterials
            );
        }
        // 若当前调用者不在白名单内 且 商品已被绑定 且 拥有者不是当前调用者 则取消
        if (
            nft.isBinding &&
            PackagedProductSmartContract.ownerOf(tokenID) != msg.sender &&
            !whiteList[msg.sender]
        ) {
            return (
                false,
                "warning,this commodity has been bound",
                PackagedProductNFTMapping[0x0],
                trades,
                rawMaterials
            );
        }
        // 根据生产批次获取原材料ID
        uint256[] memory rawMaterialIDs = ProductsLotNFTMapping[
                        nft.productLotID
            ].rawMaterials;
        // 创建返回原材料信息数组
        rawMaterials = new RMInPP[](rawMaterialIDs.length);
        for (uint256 i = 0; i < rawMaterials.length; i++) {
            // 根据原材料ID获取原材料URI
            rawMaterials[i].name = RawMaterialNFTMapping[rawMaterialIDs[i]]
                .name;
            rawMaterials[i].tokenID = rawMaterialIDs[i];
        }
        nft.owner = PackagedProductSmartContract.ownerOf(tokenID);
        nft.ownerName = User[nft.owner];
        nft.name = ProductsLotNFTMapping[nft.productLotID].name;
        nft.producerName = ProductsLotNFTMapping[nft.productLotID].producerName;
        return (
            true,
            "Success",
            nft,
            nft.trade,
            rawMaterials
        );
    }

    // 获取指定下生产批次的信息
    function getProductsLotNFT(uint256 tokenID)
    public
    view
    returns (
        ProductsLotNFT memory,
        uint256[] memory,
        uint256[] memory
    )
    {
        return (
            ProductsLotNFTMapping[tokenID],
            ProductsLotNFTMapping[tokenID].rawMaterials,
            ProductsLotNFTMapping[tokenID].products
        );
    }

    /** 原料业务逻辑 **/
    // 初始化原料NFT
    function InitRawMaterialsNFT(
        address from,
        uint256 tokenID,
        uint128 initSum,
        string memory name
    ) external {
        // 获取NFT
        RawMaterialNFT storage nft = RawMaterialNFTMapping[tokenID];
        // 设置生产厂商以及生产时间
        nft.tokenID = tokenID;
        nft.supplierName = User[from];
        nft.produceTime = block.timestamp;
        nft.totalSum = initSum;
        nft.name = name;
    }

    // 记录原料的交易记录
    function recordRawMaterialsTransfer(
        address from,
        address to,
        uint256 tokenID
    ) external {
        require(
            from == RawMaterialSmartContract.ownerOf(tokenID),
            "this token is not belong this user"
        );
        RawMaterialNFT storage nft = RawMaterialNFTMapping[tokenID];
        nft.supplierTime = block.timestamp;
        nft.producerName = User[to];
    }

    // 检查原材料拥有者是否符合
    function checkRawMaterialsOwner(address sender, uint256[] memory tokenIDs)
    external
    view
    {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            require(
                RawMaterialSmartContract.ownerOf(tokenIDs[i]) == sender,
                "The user isn't owner of raw material"
            );
        }
    }

    // 检查原材料剩余总量是否足够消耗
    function checkRawMaterialsTotalSum(
        uint256[] memory tokenIDs,
        uint128[] memory resumes
    ) external view {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            require(
                RawMaterialNFTMapping[tokenIDs[i]].totalSum >= resumes[i],
                "The total surplus of raw materials is insufficient for consumption"
            );
        }
    }

    // 查询RawMaterialsNFT当前的分销信息
    function getRawMaterialsNFT(uint256 tokenID)
    public
    view
    returns (
        bool,
        string memory,
        RawMaterialNFT memory nft,
        uint256[] memory products,
        uint128[] memory resumes
    )
    {
        // 尝试获取RawMaterialsNFTPackagedProductsNFT
        nft = RawMaterialNFTMapping[tokenID];
        // 如果不存在则取消
        if (nft.tokenID == 0x0)
            return (
                false,
                "The tokenID is not exist",
                nft,
                products,
                resumes
            );
        else
            return (
                true,
                "Success",
                nft,
                nft.productLots,
                nft.resumeLots
            );
    }

    /** 批次业务逻辑 **/

    /** 原料 **/

    // 检查是否符合条件
    function checkInAndBelongRawMaterialsMapping(
        address owner,
        uint256[] memory _childIDs
    ) external view {
        for (uint256 i = 0; i < _childIDs.length; i++) {
            uint256 tokenID = RawMaterialNFTMapping[_childIDs[i]].tokenID;
            require(tokenID != 0x0, "RawMaterials not exist");
            require(
                RawMaterialSmartContract.ownerOf(tokenID) == owner,
                "user is not owner"
            );
            require(
                RawMaterialNFTMapping[_childIDs[i]].lotID == 0x0,
                "RawMaterials has belong a lot"
            );
        }
    }

    // 关联批次和原料
    function LinkParentNFT2RawMaterials(
        uint256 tokenID,
        uint256[] memory _childIDs
    ) external {
        Lot2RawMaterials[tokenID] = _childIDs;
        for (uint256 i = 0; i < _childIDs.length; i++) {
            RawMaterialNFT storage nft = RawMaterialNFTMapping[_childIDs[i]];
            nft.lotID = tokenID;
        }
    }

    // 根据批次查询所有同批次原料token
    function getRawMaterialsByToken(uint256 tokenID)
    public
    view
    returns (uint256[] memory)
    {
        return Lot2RawMaterials[tokenID];
    }

    /** 生产 **/

    // 关联生产批次和成品
    function LinkParentNFT2Products(uint256 tokenID, uint256[] memory _childIDs)
    external
    {
        ProductsLotNFTMapping[tokenID].products = _childIDs;
        for (uint256 i = 0; i < _childIDs.length; i++) {
            PackagedProductNFTMapping[_childIDs[i]].productLotID = tokenID;
        }
    }

    /** 包装 **/

    // 检查是否符合条件
    function checkInAndBelongPackagesMapping(
        address owner,
        uint256[] memory _childIDs
    ) external view {
        for (uint256 i = 0; i < _childIDs.length; i++) {
            // 获取TOKEN
            uint256 tokenID = PackagedProductNFTMapping[_childIDs[i]].tokenID;
            // 检查TOKEN有效
            require(tokenID != 0x0, "PackagedProducts not exist");
            // 检查用户是否为TOKEN的所有者
            require(
                PackagedProductSmartContract.ownerOf(tokenID) == owner,
                "user is not owner"
            );
            // 检查该TOKEN是否已绑定其他批次
            require(
                PackagedProductNFTMapping[_childIDs[i]].packageLotID == 0x0,
                "PackagedProducts has belong a packageLotID"
            );
        }
    }

    // 关联包装批次和成品
    function LinkParentNFT2Packages(
        uint256 tokenID,
        string memory name,
        uint256[] memory _childIDs
    ) external {
        // 包装未拆开
        PackagedLotNFTMapping[tokenID].isBinding = true;
        PackagedLotNFTMapping[tokenID].tokenID = tokenID;
        PackagedLotNFTMapping[tokenID].name = name;
        for (uint256 i = 0; i < _childIDs.length; i++) {
            // 产品nft记录包装批次
            PackagedProductNFTMapping[_childIDs[i]].packageLotID = tokenID;
            // 包装批次记录产品nft
            PackagedLotNFTMapping[tokenID].products.push(_childIDs[i]);
        }
    }

    // 获取包装内所有产品的Token
    function getProductsFromPackages(uint256 tokenID)
    public
    view
    returns (
        PackagedLotNFT memory nft,
        uint256[] memory
    )
    {
        nft = PackagedLotNFTMapping[tokenID];
        nft.owner = PackageLotSmartContract.ownerOf(tokenID);
        nft.ownerName = User[nft.owner];
        return (nft, nft.products);
    }

    /** 交易记录 **/
    function _beforePackageLotTransfer(
        address from,
        address to,
        uint256 tokenID
    ) external {
        // 检查是否为包装批次
        require(
            PackagedLotNFTMapping[tokenID].tokenID != 0x0,
            "PackageLot is not exist"
        );
        // 检查包装是否完整
        require(
            PackagedLotNFTMapping[tokenID].isBinding,
            "PackageLot is not binding"
        );
        // 获取包装内的所有产品
        uint256[] memory tokenIDs = PackagedLotNFTMapping[tokenID].products;
        // 批量转移产品NFT
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            PackagedProductSmartContract.transferFrom(from, to, tokenIDs[i]);
        }
        PackagedLotNFTMapping[tokenID].isBinding = true;
    }

    /** 列表查询 **/

    // 产品

    function listForProduct (bool isOwner) public view returns (ListElement[] memory result) {
        result = list(isOwner, address(PackagedProductSmartContract));
        for (uint i = 0; i < result.length; i++)
            result[i].name = ProductsLotNFTMapping[
                                PackagedProductNFTMapping[result[i].tokenID].productLotID
                ].name;
    }

    // 包装

    function listForPackage (bool isOwner) public view returns (ListElement[] memory result) {
        result = list(isOwner, address(PackageLotSmartContract));
        for (uint i = 0; i < result.length; i++) result[i].name = PackagedLotNFTMapping[result[i].tokenID].name;
    }

    // 原料

    function listForRawMaterial (bool isOwner) public view returns (ListElement[] memory result) {
        result = list(isOwner, address(RawMaterialSmartContract));
        for (uint i = 0; i < result.length; i++) result[i].name = RawMaterialNFTMapping[result[i].tokenID].name;
    }

    function list(bool isOwner, address smartContract)
    internal
    view
    returns (ListElement[] memory result)
    {
        uint256[] memory tokenIDs;
        // 判断是否只需要查询自己的
        if (isOwner) {
            // 获取自己的所有NFT
            tokenIDs = Base(smartContract).getTokensFromOwner(
                msg.sender
            );
        } else {
            // 获取所有NFT
            tokenIDs = Base(smartContract).getTokens();
        }
        result = new ListElement[](tokenIDs.length);
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            result[i].tokenID = tokenIDs[i];
            result[i].owner = Base(smartContract).ownerOf(tokenIDs[i]);
            result[i].ownerName = User[result[i].owner];
        }
    }

    // 获取统计信息
    function getStatist()
    public
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        uint256 rmBalance = RawMaterialSmartContract.balanceOf(msg.sender);
        uint256 ppBalance = PackagedProductSmartContract.balanceOf(msg.sender);
        uint256 pkBalance = PackageLotSmartContract.balanceOf(msg.sender);
        address[] memory repositorys = RepositoryMapping[msg.sender];
        for (uint i = 0; i < repositorys.length; i++) {
            address repository = repositorys[i];
            rmBalance += RawMaterialSmartContract.balanceOf(repository);
            ppBalance += PackagedProductSmartContract.balanceOf(repository);
            pkBalance += PackageLotSmartContract.balanceOf(repository);
        }
        return (
        // 原材料NFT总数量
            RawMaterialSmartContract.totalSupply(),
        // 产品NFT总数量
            PackagedProductSmartContract.totalSupply(),
        // 包装批次总数量
            PackageLotSmartContract.totalSupply(),
        // 发送者拥有的原材料NFT数量
            rmBalance,
        // 发送者拥有的产品NFT数量
            ppBalance,
        // 发送者拥有的包装NFT数量
            pkBalance
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
