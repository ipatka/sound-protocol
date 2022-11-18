// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import { IERC165 } from "openzeppelin/utils/introspection/IERC165.sol";
import { ISoundFeeRegistry } from "@core/interfaces/ISoundFeeRegistry.sol";
import { IAlbumRedemptionMinter, MintData, MintInfo } from "./interfaces/IAlbumRedemptionMinter.sol";
import { BaseMinter } from "./BaseMinter.sol";
import { IMinterModule } from "@core/interfaces/IMinterModule.sol";
import { ISoundEditionV1, EditionInfo } from "@core/interfaces/ISoundEditionV1.sol";
import { IRarityShuffleMetadata } from "./interfaces/IRarityShuffleMetadata.sol";
import { IERC721ABurnableUpgradeable } from "chiru-labs/ERC721A-Upgradeable/extensions/ERC721ABurnableUpgradeable.sol";

error LogAddys(address a, address b);

/*
 * @title EditionMaxMinter
 * @notice Module for unpermissioned mints of Sound editions.
 * @author Sound.xyz
 */
contract AlbumRedemptionMinter is IAlbumRedemptionMinter, BaseMinter {
    // =============================================================
    //                            STORAGE
    // =============================================================

    /**
     * @dev Edition mint data
     * edition => mintId => MintData
     */
    mapping(address => mapping(uint128 => MintData)) internal _mintData;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(ISoundFeeRegistry feeRegistry_) BaseMinter(feeRegistry_) {}

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc IAlbumRedemptionMinter
     */
    function createAlbumRedemptionMint(
        address songEdition,
        address albumEdition,
        uint32 requiredRedemptions,
        uint32 startTime,
        uint32 endTime,
        uint32 maxMintablePerAccount
    ) public returns (uint128 mintId) {
        if (maxMintablePerAccount == 0) revert MaxMintablePerAccountIsZero();

        mintId = _createEditionMint(albumEdition, startTime, endTime, 0);

        MintData storage data = _mintData[albumEdition][mintId];
        data.maxMintablePerAccount = maxMintablePerAccount;
        data.requiredRedemptions = requiredRedemptions;
        data.redemptionContract = songEdition;

        // prettier-ignore
        emit AlbumRedemptionMintCreated(
            albumEdition,
            mintId,
            songEdition,
            requiredRedemptions,
            startTime,
            endTime,
            maxMintablePerAccount
        );
    }

    /**
     * @inheritdoc IAlbumRedemptionMinter
     */
    function mint(
        address edition,
        address redemptionContract,
        uint128 mintId,
        uint256[] calldata tokenIds
    ) public {
        MintData storage data = _mintData[edition][mintId];
        
        ISoundEditionV1 _songEdition = ISoundEditionV1(data.redemptionContract);
        IRarityShuffleMetadata _meta = IRarityShuffleMetadata(_songEdition.metadataModule());
        
        for (uint256 index = 0; index < data.requiredRedemptions; index++) {
          if (_meta.getShuffledTokenId(tokenIds[index]) != (index + 1)) revert InvalidTokenForRedemption(_meta.getShuffledTokenId(tokenIds[index]), (index + 1), index, tokenIds[index]);
          if (_songEdition.ownerOf(tokenIds[index]) != msg.sender) revert OfferedTokenNotOwned();
          
          IERC721ABurnableUpgradeable(address(_songEdition)).burn(tokenIds[index]); /*Will revert if contract is not approved*/
        }

        unchecked {
            // Check the additional `requestedQuantity` does not exceed the maximum mintable per account.
            uint256 numberMinted = ISoundEditionV1(edition).numberMinted(msg.sender);
            // Won't overflow. The total number of tokens minted in `edition` won't exceed `type(uint32).max`,
            // and `quantity` has 32 bits.
            if (numberMinted + 1 > data.maxMintablePerAccount) revert ExceedsMaxPerAccount();
        }

        _mint(edition, mintId, 1, address(0));
    }


    /**
     * @inheritdoc IAlbumRedemptionMinter
     */
    function setMaxMintablePerAccount(
        address edition,
        uint128 mintId,
        uint32 maxMintablePerAccount
    ) public onlyEditionOwnerOrAdmin(edition) {
        if (maxMintablePerAccount == 0) revert MaxMintablePerAccountIsZero();
        _mintData[edition][mintId].maxMintablePerAccount = maxMintablePerAccount;
        emit MaxMintablePerAccountSet(edition, mintId, maxMintablePerAccount);
    }

    // =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc IMinterModule
     */
    function totalPrice(
        address,
        uint128,
        address, /* minter */
        uint32
    ) public view virtual override(BaseMinter, IMinterModule) returns (uint128) {
        unchecked {
            // Will not overflow, as `price` is 96 bits, and `quantity` is 32 bits. 96 + 32 = 128.
            return 0;
        }
    }

    /**
     * @inheritdoc IAlbumRedemptionMinter
     */
    function mintInfo(address edition, uint128 mintId) external view returns (MintInfo memory info) {
        BaseData memory baseData = _baseData[edition][mintId];
        MintData storage mintData = _mintData[edition][mintId];

        EditionInfo memory editionInfo = ISoundEditionV1(edition).editionInfo();

        info.startTime = baseData.startTime;
        info.endTime = baseData.endTime;
        info.mintPaused = baseData.mintPaused;
        info.requiredRedemptions = mintData.requiredRedemptions;
        info.redemptionContract = mintData.redemptionContract;
        info.maxMintableLower = editionInfo.editionMaxMintableLower;
        info.maxMintableUpper = editionInfo.editionMaxMintableUpper;
        info.cutoffTime = editionInfo.editionCutoffTime;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override(IERC165, BaseMinter) returns (bool) {
        return BaseMinter.supportsInterface(interfaceId) || interfaceId == type(IAlbumRedemptionMinter).interfaceId;
    }

    /**
     * @inheritdoc IMinterModule
     */
    function moduleInterfaceId() public pure returns (bytes4) {
        return type(IAlbumRedemptionMinter).interfaceId;
    }
}
