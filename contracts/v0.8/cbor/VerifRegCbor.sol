/*******************************************************************************
 *   (c) 2022 Zondax AG
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ********************************************************************************/
//
// THIS CODE WAS SECURITY REVIEWED BY KUDELSKI SECURITY, BUT NOT FORMALLY AUDITED

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "solidity-cborutils/contracts/CBOR.sol";

import "../types/CommonTypes.sol";
import "../types/VerifRegTypes.sol";

import "../utils/CborDecode.sol";
import "../utils/Misc.sol";
import "../utils/Errors.sol";

import "./BigIntCbor.sol";
import "./FilecoinCbor.sol";
import "./BytesCbor.sol";

/// @title This library is a set of functions meant to handle CBOR parameters serialization and return values deserialization for VerifReg actor exported methods.
/// @author Zondax AG
library VerifRegCBOR {
    using CBOR for CBOR.CBORBuffer;
    using CBORDecoder for bytes;
    using BytesCBOR for bytes;
    using BigIntCBOR for *;
    using FilecoinCBOR for *;

    /// @notice serialize GetClaimsParams struct to cbor in order to pass as arguments to the verified registry actor
    /// @param params GetClaimsParams to serialize as cbor
    /// @return cbor serialized data as bytes
    function serializeGetClaimsParams(VerifRegTypes.GetClaimsParams memory params) internal pure returns (bytes memory) {
        uint256 capacity = 0;
        uint claimIdsLen = params.claim_ids.length;

        capacity += Misc.getPrefixSize(2);
        capacity += Misc.getFilActorIdSize(params.provider);
        capacity += Misc.getPrefixSize(claimIdsLen);
        for (uint i = 0; i < claimIdsLen; i++) {
            capacity += Misc.getFilActorIdSize(params.claim_ids[i]);
        }
        CBOR.CBORBuffer memory buf = CBOR.create(capacity);

        buf.startFixedArray(2);
        buf.writeFilActorId(params.provider);
        buf.startFixedArray(uint64(claimIdsLen));
        for (uint i = 0; i < claimIdsLen; i++) {
            buf.writeFilActorId(params.claim_ids[i]);
        }

        return buf.data();
    }

    /// @notice deserialize GetClaimsReturn struct from cbor encoded bytes coming from a verified registry actor call
    /// @param rawResp cbor encoded response
    /// @return ret new instance of GetClaimsReturn created based on parsed data
    function deserializeGetClaimsReturn(bytes memory rawResp) internal pure returns (VerifRegTypes.GetClaimsReturn memory ret) {
        uint byteIdx = 0;
        uint len;
        uint ilen;

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        if (!(len == 2)) {
            revert Errors.InvalidArrayLength(2, len);
        }

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        if (!(len == 2)) {
            revert Errors.InvalidArrayLength(2, len);
        }

        (ret.batch_info.success_count, byteIdx) = rawResp.readUInt32(byteIdx);

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        ret.batch_info.fail_codes = new CommonTypes.FailCode[](len);

        for (uint i = 0; i < len; i++) {
            (ilen, byteIdx) = rawResp.readFixedArray(byteIdx);
            if (!(len == 2)) {
                revert Errors.InvalidArrayLength(2, len);
            }

            (ret.batch_info.fail_codes[i].idx, byteIdx) = rawResp.readUInt32(byteIdx);
            (ret.batch_info.fail_codes[i].code, byteIdx) = rawResp.readUInt32(byteIdx);
        }

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        ret.claims = new VerifRegTypes.Claim[](len);

        for (uint i = 0; i < len; i++) {
            (ilen, byteIdx) = rawResp.readFixedArray(byteIdx);
            if (!(ilen == 8)) {
                revert Errors.InvalidArrayLength(8, ilen);
            }

            (ret.claims[i].provider, byteIdx) = rawResp.readFilActorId(byteIdx);
            (ret.claims[i].client, byteIdx) = rawResp.readFilActorId(byteIdx);
            (ret.claims[i].data, byteIdx) = rawResp.readBytes(byteIdx);
            (ret.claims[i].size, byteIdx) = rawResp.readUInt64(byteIdx);
            (ret.claims[i].term_min, byteIdx) = rawResp.readChainEpoch(byteIdx);
            (ret.claims[i].term_max, byteIdx) = rawResp.readChainEpoch(byteIdx);
            (ret.claims[i].term_start, byteIdx) = rawResp.readChainEpoch(byteIdx);
            (ret.claims[i].sector, byteIdx) = rawResp.readFilActorId(byteIdx);
        }

        return ret;
    }

    /// @notice serialize AddVerifiedClientParams struct to cbor in order to pass as arguments to the verified registry actor
    /// @param params AddVerifiedClientParams to serialize as cbor
    /// @return cbor serialized data as bytes
    function serializeAddVerifiedClientParams(VerifRegTypes.AddVerifiedClientParams memory params) internal pure returns (bytes memory) {
        uint256 capacity = 0;
        bytes memory allowance = params.allowance.serializeBigInt();

        capacity += Misc.getPrefixSize(2);
        capacity += Misc.getBytesSize(params.addr.data);
        capacity += Misc.getBytesSize(allowance);
        CBOR.CBORBuffer memory buf = CBOR.create(capacity);

        buf.startFixedArray(2);
        buf.writeBytes(params.addr.data);
        buf.writeBytes(allowance);

        return buf.data();
    }

    /// @notice serialize RemoveExpiredAllocationsParams struct to cbor in order to pass as arguments to the verified registry actor
    /// @param params RemoveExpiredAllocationsParams to serialize as cbor
    /// @return cbor serialized data as bytes
    function serializeRemoveExpiredAllocationsParams(VerifRegTypes.RemoveExpiredAllocationsParams memory params) internal pure returns (bytes memory) {
        uint256 capacity = 0;
        uint allocationIdsLen = params.allocation_ids.length;

        capacity += Misc.getPrefixSize(2);
        capacity += Misc.getFilActorIdSize(params.client);
        capacity += Misc.getPrefixSize(allocationIdsLen);
        for (uint i = 0; i < allocationIdsLen; i++) {
            capacity += Misc.getFilActorIdSize(params.allocation_ids[i]);
        }
        CBOR.CBORBuffer memory buf = CBOR.create(capacity);

        buf.startFixedArray(2);
        buf.writeFilActorId(params.client);
        buf.startFixedArray(uint64(allocationIdsLen));
        for (uint i = 0; i < allocationIdsLen; i++) {
            buf.writeFilActorId(params.allocation_ids[i]);
        }

        return buf.data();
    }

    /// @notice deserialize RemoveExpiredAllocationsReturn struct from cbor encoded bytes coming from a verified registry actor call
    /// @param rawResp cbor encoded response
    /// @return ret new instance of RemoveExpiredAllocationsReturn created based on parsed data
    function deserializeRemoveExpiredAllocationsReturn(bytes memory rawResp) internal pure returns (VerifRegTypes.RemoveExpiredAllocationsReturn memory ret) {
        uint byteIdx = 0;
        uint len;
        uint ilen;

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        if (!(len == 3)) {
            revert Errors.InvalidArrayLength(3, len);
        }

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        ret.considered = new CommonTypes.FilActorId[](len);

        for (uint i = 0; i < len; i++) {
            (ret.considered[i], byteIdx) = rawResp.readFilActorId(byteIdx);
        }

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        if (!(len == 2)) {
            revert Errors.InvalidArrayLength(2, len);
        }

        (ret.results.success_count, byteIdx) = rawResp.readUInt32(byteIdx);

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        ret.results.fail_codes = new CommonTypes.FailCode[](len);

        for (uint i = 0; i < len; i++) {
            (ilen, byteIdx) = rawResp.readFixedArray(byteIdx);
            if (!(len == 2)) {
                revert Errors.InvalidArrayLength(2, len);
            }

            (ret.results.fail_codes[i].idx, byteIdx) = rawResp.readUInt32(byteIdx);
            (ret.results.fail_codes[i].code, byteIdx) = rawResp.readUInt32(byteIdx);
        }

        bytes memory tmp;
        (tmp, byteIdx) = rawResp.readBytes(byteIdx);
        ret.datacap_recovered = tmp.deserializeBytesBigInt();

        return ret;
    }

    /// @notice serialize ExtendClaimTermsParams struct to cbor in order to pass as arguments to the verified registry actor
    /// @param terms ExtendClaimTermsParams to serialize as cbor
    /// @return cbor serialized data as bytes
    function serializeExtendClaimTermsParams(VerifRegTypes.ClaimTerm[] memory terms) internal pure returns (bytes memory) {
        uint256 capacity = 0;
        uint termsLen = terms.length;

        capacity += Misc.getPrefixSize(1);
        capacity += Misc.getPrefixSize(termsLen);
        for (uint i = 0; i < termsLen; i++) {
            capacity += Misc.getPrefixSize(3);
            capacity += Misc.getFilActorIdSize(terms[i].provider);
            capacity += Misc.getFilActorIdSize(terms[i].claim_id);
            capacity += Misc.getChainEpochSize(terms[i].term_max);
        }
        CBOR.CBORBuffer memory buf = CBOR.create(capacity);

        buf.startFixedArray(1);
        buf.startFixedArray(uint64(termsLen));
        for (uint i = 0; i < termsLen; i++) {
            buf.startFixedArray(3);
            buf.writeFilActorId(terms[i].provider);
            buf.writeFilActorId(terms[i].claim_id);
            buf.writeChainEpoch(terms[i].term_max);
        }

        return buf.data();
    }

    /// @notice deserialize BatchReturn struct from cbor encoded bytes coming from a verified registry actor call
    /// @param rawResp cbor encoded response
    /// @return ret new instance of BatchReturn created based on parsed data
    function deserializeBatchReturn(bytes memory rawResp) internal pure returns (CommonTypes.BatchReturn memory ret) {
        uint byteIdx = 0;
        uint len;
        uint ilen;

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        if (!(len == 2)) {
            revert Errors.InvalidArrayLength(2, len);
        }

        (ret.success_count, byteIdx) = rawResp.readUInt32(byteIdx);

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        ret.fail_codes = new CommonTypes.FailCode[](len);

        for (uint i = 0; i < len; i++) {
            (ilen, byteIdx) = rawResp.readFixedArray(byteIdx);
            if (!(len == 2)) {
                revert Errors.InvalidArrayLength(2, len);
            }

            (ret.fail_codes[i].idx, byteIdx) = rawResp.readUInt32(byteIdx);
            (ret.fail_codes[i].code, byteIdx) = rawResp.readUInt32(byteIdx);
        }

        return ret;
    }

    /// @notice serialize RemoveExpiredClaimsParams struct to cbor in order to pass as arguments to the verified registry actor
    /// @param params RemoveExpiredClaimsParams to serialize as cbor
    /// @return cbor serialized data as bytes
    function serializeRemoveExpiredClaimsParams(VerifRegTypes.RemoveExpiredClaimsParams memory params) internal pure returns (bytes memory) {
        uint256 capacity = 0;
        uint claimIdsLen = params.claim_ids.length;

        capacity += Misc.getPrefixSize(2);
        capacity += Misc.getFilActorIdSize(params.provider);
        capacity += Misc.getPrefixSize(claimIdsLen);
        for (uint i = 0; i < claimIdsLen; i++) {
            capacity += Misc.getFilActorIdSize(params.claim_ids[i]);
        }
        CBOR.CBORBuffer memory buf = CBOR.create(capacity);

        buf.startFixedArray(2);
        buf.writeFilActorId(params.provider);
        buf.startFixedArray(uint64(claimIdsLen));
        for (uint i = 0; i < claimIdsLen; i++) {
            buf.writeFilActorId(params.claim_ids[i]);
        }

        return buf.data();
    }

    /// @notice deserialize RemoveExpiredClaimsReturn struct from cbor encoded bytes coming from a verified registry actor call
    /// @param rawResp cbor encoded response
    /// @return ret new instance of RemoveExpiredClaimsReturn created based on parsed data
    function deserializeRemoveExpiredClaimsReturn(bytes memory rawResp) internal pure returns (VerifRegTypes.RemoveExpiredClaimsReturn memory ret) {
        uint byteIdx = 0;
        uint len;
        uint ilen;

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        if (!(len == 2)) {
            revert Errors.InvalidArrayLength(2, len);
        }

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        ret.considered = new CommonTypes.FilActorId[](len);

        for (uint i = 0; i < len; i++) {
            (ret.considered[i], byteIdx) = rawResp.readFilActorId(byteIdx);
        }

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        if (!(len == 2)) {
            revert Errors.InvalidArrayLength(2, len);
        }

        (ret.results.success_count, byteIdx) = rawResp.readUInt32(byteIdx);

        (len, byteIdx) = rawResp.readFixedArray(byteIdx);
        ret.results.fail_codes = new CommonTypes.FailCode[](len);

        for (uint i = 0; i < len; i++) {
            (ilen, byteIdx) = rawResp.readFixedArray(byteIdx);
            if (!(len == 2)) {
                revert Errors.InvalidArrayLength(2, len);
            }

            (ret.results.fail_codes[i].idx, byteIdx) = rawResp.readUInt32(byteIdx);
            (ret.results.fail_codes[i].code, byteIdx) = rawResp.readUInt32(byteIdx);
        }

        return ret;
    }
}
