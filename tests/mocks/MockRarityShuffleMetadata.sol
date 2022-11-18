// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { RarityShuffleMetadata } from "@modules/RarityShuffleMetadata.sol";

contract MockRarityShuffleMetadata is RarityShuffleMetadata {

    constructor(
        address _edition,
        uint16 _availableCount,
        uint256 _nRanges,
        uint256[] memory _ranges
    ) RarityShuffleMetadata(_edition, _availableCount, _nRanges, _ranges) {}

  function setOffset(uint256 tokenId, uint256 offset) public {
    offsets[tokenId] = offset;
  }
}
