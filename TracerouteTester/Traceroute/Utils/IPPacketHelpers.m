//
//  IPPacketHelpers.c
//  PingTester
//
//  Created by Bruno Bulic on 3/13/13.
//
//

#import "MMTracerouteDefines.h"

char * readableAddressFromCharArray(const uint8_t * address) {
    
    char element[30] = "";
    
    for(uint8_t i = 0; i < 4; i++)
    {
        char string[5];
        const uint8_t section = address[i];
        int size = sprintf(string, "%d.", section);
        
        char * new = malloc(size+1);
        strcpy(new, string);
        strcat(element, new);
        free(new);
    }
    
    char * result = malloc(strlen(element));
    strcpy(result, element);
    
    return result;
}

char * sourceAddress(const IPHeader * h) {
    return readableAddressFromCharArray(h->sourceAddress);
}
char * destAddress(const IPHeader *h) {
    return readableAddressFromCharArray(h->destinationAddress);
}
