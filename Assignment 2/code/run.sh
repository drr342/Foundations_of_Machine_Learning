#!/bin/bash

make
sed -n -e '1,2316p' svmguide1.shuffled > svmguide1.train
sed -n -e '2317,3089p' svmguide1.shuffled > svmguide1.test
 ./svm-scale -s scale.params svmguide1.train > svmguide1.train.scale
 ./svm-scale -r scale.params svmguide1.test > svmguide1.test.scale

echo "C" > data1.csv
for i in `seq -15 15`; do
	c=$(echo "scale=8; 2^$i" | bc -l)
	echo $c >> data1.csv
done
echo "================= Cross Validation ================="
for j in `seq 1 4`; do
	echo "pe$j,sd$j" > file$j
	for i in `seq -15 15`; do
    	c=$(echo "scale=8; 2^$i" | bc -l)
		echo "Training with C=$c, d=$j..."
    	./svm-train -s 0 -t 1 -d $j -c $c -v 10 -q svmguide1.train.scale > temp
		mpe=$(grep -P -o 'mpe = \d+.\d+' temp | grep -P -o '\d+.\d+')
		mpeSD=$(grep -P -o 'mpeSD = \d+.\d+' temp | grep -P -o '\d+.\d+')
		echo $mpe,$mpeSD >> file$j
	done
done
for j in `seq 1 4`; do
	paste -d , data1.csv file$j > temp
	mv temp data1.csv
	rm file$j
done

echo ""
echo "====================== Testing ====================="
echo "d,err_train,err_test,nSV,nBSV" > data2.csv
for j in `seq 1 20`; do
	echo "Testing with d=$j..."
	./svm-train -s 0 -t 1 -d $j -c 8192 -v 10 -q svmguide1.train.scale > temp
	err_train=$(grep -P -o 'mpe = \d+.\d+' temp | grep -P -o '\d+.\d+')
	./svm-train -s 0 -t 1 -d $j -c 8192 svmguide1.train.scale svmguide1.model > temp
	nSV=$(grep -P -o 'Total nSV = \d+' temp | grep -P -o '\d+')
	nBSV=$(grep -P -o 'nBSV = \d+' temp | grep -P -o '\d+')
	./svm-predict svmguide1.test.scale svmguide1.model predict > temp
	acc=$(grep -P -o 'Accuracy = \d+.\d+' temp | grep -P -o '\d+.\d+')
	err_test=$(echo "scale=6;1-$acc/100" | bc -l)
	echo "$j,$err_train,$err_test,$nSV,$nBSV" >> data2.csv
done
rm temp predict
