import { ReactPaginate } from "react-paginate";
import { useState } from "react";

export const NFTCard = ({nft})=>{
    const [isHovering, setIsHovering] = useState(false);

    const handleMouseOver = () => {
      setIsHovering(true);
    };
  
    const handleMouseOut = () => {
      setIsHovering(false);
    };
    return(
        <div className="w-1/3 flex flex-col transition duration-500 hover:scale-110 border-2 border-black border-r-3">
            <div className="rounded-md">
                <img className="object-cover h-128 w-full rounded-t-md" src={nft.media[0].gateway}/>
            </div>
            <div className="flex flex-col y-gap-2 px-2 py-3 bg-slate-100 rounded-b-md h-110 ">
                <div class="mr-3 ">
                <h2 className="text-xl text-black">
                   <b> Name: </b>{nft.title}
                </h2>
                
                <p className="text-black"><b>Token ID: </b>{nft.id.tokenId.substr(nft.id.tokenId.length - 4)}</p>
                
                <p onClick={() => {navigator.clipboard.writeText(nft.contract.address);alert("Copied address");}} onMouseOver={handleMouseOver} onMouseOut={handleMouseOut} className="text-black"><b>Contract Address: </b>{nft.contract.address.substr(0,4)}...{nft.contract.address.substr(nft.contract.address.length - 4)}  {isHovering && <p>Click to copy</p>}</p>
                
                <p className="text-black"><b>Description: </b>{nft.description?.substr(0,50)}...</p>
                
                <div  className=" flex justify-center mt-2  "><a className={"cursor-pointer shadow bg-purple-500 hover:bg-purple-400 focus:shadow-outline focus:outline-none text-white hover:font-bold py-2 px-4 rounded"} target={"_blank"} href={`https://etherscan.io/address/${nft.contract.address}`}>View on etherscan !</a></div>
    
                </div>
            </div>
        </div>
    );
}