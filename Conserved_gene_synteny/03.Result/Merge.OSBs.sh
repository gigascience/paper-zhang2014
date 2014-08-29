date
cat ../01.Birds/Orthologous_Syntenic_Blocks/*/*/2species.ort.per  | awk '{ave=($3+$5)/2}{print ave"\t"$9/2}' | awk '{print $_"\t""Birds"}' > Birds.ave.div.data
cat ../02.Mammals/Orthologous_Syntenic_Blocks/*/*/2species.ort.per | awk '{ave=($3+$5)/2}{print ave"\t"$9}' | awk '{print $_"\t""Mammals"}' > Mammals.ave.div.data
cat Mammals.ave.div.data Birds.ave.div.data | awk '$3 !="Mammals" ||  $2 <197' |  awk 'FNR==1{print "Percentage\tDivergence\tClade" } {print $0}'  > Both.ave.div.data
date
