#$ -S /bin/bash 
./SOAPdenovo-63mer pregraph -s SOAPdenovo.cfg -K 27 -d 1 -o species -p 24 >pregraph.log
./SOAPdenovo-63mer contig -g species -M 3 >contig.log
./SOAPdenovo-63mer map -s SOAPdenovo.cfg -g species -p 24 >map.log
./SOAPdenovo-63mer scaff -g species -F -p 24 >scaffold.log
