function swap(key1, key2){
	
	temp = sortedUsers[key1];
	sortedUsers[key1] = sortedUsers[key2];
	sortedUsers[key2] = temp;
}

BEGIN {
	
	tUsers = 0;
	tFiles = 0;
	tHidden = 0;
	tDir = 0;
	tOther = 0;
	tBytes = 0;
	
	oldestFile = "None";
	newestFile = "None";
	
}

#skip total disk usage line, as well as '.' and '..' directories

FNR < 4 {
	next
}

#skip any incorrectly formatted lines (if any)

NF < 8 {
	next
}

# $1 = permissions
# $2 = links pointing to this file
# $3 = owner (user)
# $4 = group
# $5 = size in bytes
# $6 = modified date
# $7 = modified time
# $8 = file name

#any file (including directories/links!):

{
	#if current file's owner hasnt been seen yet, add it to the array of users and initialize their data with 0's
	
	if(!($3 in users)){
		
		#the value held in users[] is initialized to the order we discover them (starting at 0).
		users[$3] = tUsers;
		tUsers++;
		
		numFiles[$3] = 0;
		numHidden[$3] = 0;
		numDir[$3] = 0;
		numOther[$3] = 0;
		numBytes[$3] = 0;
		
	}
}

#if this file is a directory:

/^d/ {
	
	tDir++;
	numDir[$3]++;
	
}

#if this file is "other":

/^[^-d]/ {
	
	tOther++;
	numOther[$3]++;
	
}

#if this file is normal:

/^-/ {
	
	tFiles++;
	numFiles[$3]++;
	
	tBytes += $5;
	numBytes[$3] += $5;
	
	#if this file is hidden:
	
	if(match($8, /^\./)) {
		
		tHidden++;
		numHidden[$3]++;
		
	}
	
	#initialize oldest and newest files to the first regular file we find
	
	if(oldestFile == "None"){
		
		oldestFile = $0;
		oldestDate = $6 $7;
		
		newestFile = $0;
		newestDate = $6 $7;
	}
	
	#update oldestFile and newestFile if necessary
	
	if($6 $7 < oldestDate){
	
		oldestFile = $0;
		oldestDate = $6 $7;
		
	}
	
	if($6 $7 > newestDate){
	
		newestFile = $0;
		newestDate = $6 $7;
		
	}
}

END {
	
	#make new array holding our users in order, with an integer value (""index"") as a key.
	
	i = 0;
	for(user in users) sortedUsers[i++] = user;
	
	#sort users by amount of bytes taken (ascending).
	
	for(i = 0; i < tUsers; i++){
		for(j = 1; j < (tUsers - i); j++){
			
			#if current user's byte count is less than previous user's, swap their order
			
			if(numBytes[sortedUsers[j]] < numBytes[sortedUsers[j-1]])
				swap(j, j-1);
			
		}
	}
	
	#break any ties in the sorted users array (a-z).
	
	for(i = 0; i < tUsers; i++){
		for(j = 1; j < (tUsers - i); j++){
			
			#skip any non-tied entries
			if(numBytes[sortedUsers[j]] != numBytes[sortedUsers[j-1]]) continue;
			
			#if current user's name comes later than previous user's, swap their order
			
			if(sortedUsers[j] < sortedUsers[j-1])
				swap(j, j-1);
			
		}
	}
	
	#print each user's data
	
	for(i = 0; i < tUsers; i++){
		
		user = sortedUsers[i];
		
		printf("Username: %s\n", user);
		
		if(numFiles[user] > 0){
			
			printf("   Files:\n");
			printf("                All: %d\n", numFiles[user]);
			printf("             Hidden: %d\n", numHidden[user]);
			
		}
		
		if(numDir[user] > 0) 
			printf("        Directories: %d\n", numDir[user]);
		
		if(numOther[user] > 0)
			printf("             Others: %d\n", numOther[user]);
		
		if(numFiles[user] > 0)
			printf("        Storage (B): %d bytes\n", numBytes[user]);
		
		printf("\n");
	}
	
	#print oldest and newest files
	
	printf("Oldest file:\n\t%s\n", oldestFile);
	printf("Newest file:\n\t%s\n\n", newestFile);
	
	#print cumulative data
	
	printf("Total users:        \t%d\n", tUsers);
	printf("Total files:\n");
	printf("    (All / Hidden): \t( %d / %d )\n", tFiles, tHidden);
	printf("Total directories:  \t%d\n", tDir);
	printf("Total others:       \t%d\n", tOther);
	printf("Storage (B):        \t%d bytes\n\n", tBytes);

}
