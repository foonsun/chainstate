#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <hiredis/hiredis.h>

int main(int argc, const char *argv[]) {
	char file_name[] = "unspent-0-519970.csv";
	FILE *fp;
	fp = fopen(file_name, "r");
	if(!fp){
		fprintf(stderr, "failed to open file for reading\n");
		return 1;
	}
	
	char line[1000];
	char *result = NULL;
	
	redisContext *context = redisConnect("127.0.0.1", 6379);
	if(context->err) {
		redisFree(context);
		printf("connect redisserver error:%s \n", context->errstr);
	}
	while(fgets(line, 1000, fp) != NULL)
	{
		char *address = NULL;
		int value = 0;
		result = strtok(line, ";");
		int i = 0 ;
		while( result != NULL) {
			if(strcmp(result, "txid") == 0){
				break;
			}
			if(strlen(result) ==  0 )
			{
				break;
			}
			if(i == 4){
				address = result;
			}
			if(i == 3){
				value = atoi(result);
			}
			result = strtok(NULL, ";");
			i++;
		}
		if(NULL == address ){
			continue;	
		}
	printf("address:%s value:%d",address, value);
	printf("\n");
	char des[1000];
	sprintf(des,"%s %d %s","ZINCRBY bitcoin_address_balances", value, address);
	const char *cmd = des;
	redisReply *reply = (redisReply *)redisCommand(context, cmd);
	printf("reply:%s \n", reply->str);
	freeReplyObject(reply);
	}
	redisFree(context);
	fclose(fp);
	return 0;
}
