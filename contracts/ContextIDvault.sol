// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ContextIDVault
 * @author YourTeamName
 * @notice 这是一个用于Context项目的智能合约，允许用户在Injective链上
 *         安全地存储他们经过端到端加密的、高敏感的上下文数据片段。
 *         合约本身无法读取任何数据，它只作为加密数据的“保险箱”和“指针管理器”。
 */
contract ContextIDVault {
    // 1. 定义存储的数据结构
    // 每个数据片段都包含两部分：加密后的主内容，和加密后的“钥匙”
    struct EncryptedPayload {
        bytes encryptedContent; // 使用对称密钥加密后的主数据
        bytes encryptedSymKey; // 使用用户公钥加密后的对称密钥
        uint256 timestamp; // 数据上链时的时间戳，用于追踪
    }

    // 2. 核心数据结构：一个双层字典
    // mapping(用户地址 => mapping(数据唯一ID => 加密数据))
    // 这让我们可以通过 "用户地址" + "数据ID" 精准地定位任何一条加密记录
    mapping(address => mapping(string => EncryptedPayload)) public vaults;

    // 3. 定义事件（Event），方便前端监听链上活动
    // 当一个数据被成功存储时，广播这个事件
    event DataStored(address indexed user, string dataId, uint256 timestamp);
    // 当一个数据被更新时，广播这个事件
    event DataUpdated(address indexed user, string dataId, uint256 timestamp);

    /**
     * @notice 将加密后的数据片段存储到链上。
     *         如果dataId已存在，此操作会覆盖旧数据，相当于更新。
     * @param dataId 由Context后端生成的该数据片段的唯一标识符（例如UUID）
     * @param _encryptedContent 加密后的主数据
     * @param _encryptedSymKey 加密后的对称密钥
     */
    function storeData(
        string memory dataId,
        bytes memory _encryptedContent,
        bytes memory _encryptedSymKey
    ) public {
        // msg.sender 是调用此函数的钱包地址，确保数据与用户身份自动绑定
        address user = msg.sender;

        // 检查是新存储还是更新
        bool isUpdate = vaults[user][dataId].timestamp != 0;

        // 将加密数据存入双层字典中
        vaults[user][dataId] = EncryptedPayload({
            encryptedContent: _encryptedContent,
            encryptedSymKey: _encryptedSymKey,
            timestamp: block.timestamp
        });

        // 根据情况广播不同的事件
        if (isUpdate) {
            emit DataUpdated(user, dataId, block.timestamp);
        } else {
            emit DataStored(user, dataId, block.timestamp);
        }
    }

    /**
     * @notice 从链上获取指定用户和数据ID对应的加密数据。
     *         这是一个只读操作（view），调用它不花费任何Gas费。
     * @param user 要查询的用户的地址
     * @param dataId 要查询的数据的唯一ID
     * @return EncryptedPayload 结构体，包含两部分加密数据
     */
    function getData(
        address user,
        string memory dataId
    ) public view returns (EncryptedPayload memory) {
        return vaults[user][dataId];
    }
}
