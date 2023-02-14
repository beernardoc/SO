/**
 *  \file semSharedMemClient.c (implementation file)
 *
 *  \brief Problem name: Restaurant
 *
 *  Synchronization based on semaphores and shared memory.
 *  Implementation with SVIPC.
 *
 *  Definition of the operations carried out by the clients:
 *     \li waitFriends
 *     \li orderFood
 *     \li waitFood
 *     \li travel
 *     \li eat
 *     \li waitAndPay
 *
 *  \author Nuno Lau - December 2022
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <sys/types.h>
#include <string.h>
#include <math.h>

#include "probConst.h"
#include "probDataStruct.h"
#include "logging.h"
#include "sharedDataSync.h"
#include "semaphore.h"
#include "sharedMemory.h"

/** \brief logging file name */
static char nFic[51];

/** \brief shared memory block access identifier */
static int shmid;

/** \brief semaphore set access identifier */
static int semgid;

/** \brief pointer to shared memory region */
static SHARED_DATA *sh;

static bool waitFriends (int id);
static void orderFood (int id);
static void waitFood (int id);
static void travel (int id);
static void eat (int id);
static void waitAndPay (int id);

/**
 *  \brief Main program.
 *
 *  Its role is to generate the life cycle of one of intervening entities in the problem: the client.
 */
int main (int argc, char *argv[])
{
    int key;                                         /*access key to shared memory and semaphore set */
    char *tinp;                                                    /* numerical parameters test flag */
    int n;

    /* validation of command line parameters */
    if (argc != 5) { 
        freopen ("error_CT", "a", stderr);
        fprintf (stderr, "Number of parameters is incorrect!\n");
        return EXIT_FAILURE;
    }
    else {
       freopen (argv[4], "w", stderr);
       setbuf(stderr,NULL);
    }

    n = (unsigned int) strtol (argv[1], &tinp, 0);
    if ((*tinp != '\0') || (n >= TABLESIZE)) { 
        fprintf (stderr, "Client process identification is wrong!\n");
        return EXIT_FAILURE;
    }
    strcpy (nFic, argv[2]);
    key = (unsigned int) strtol (argv[3], &tinp, 0);
    if (*tinp != '\0') { 
        fprintf (stderr, "Error on the access key communication!\n");
        return EXIT_FAILURE;
    }

    /* connection to the semaphore set and the shared memory region and mapping the shared region onto the
       process address space */
    if ((semgid = semConnect (key)) == -1) { 
        perror ("error on connecting to the semaphore set");
        return EXIT_FAILURE;
    }
    if ((shmid = shmemConnect (key)) == -1) { 
        perror ("error on connecting to the shared memory region");
        return EXIT_FAILURE;
    }
    if (shmemAttach (shmid, (void **) &sh) == -1) { 
        perror ("error on mapping the shared region on the process address space");
        return EXIT_FAILURE;
    }

    /* initialize random generator */
    srandom ((unsigned int) getpid ());                                                 


    /* simulation of the life cycle of the client */
    travel(n);
    bool first = waitFriends(n);
    if (first) orderFood(n);
    waitFood(n);
    eat(n);
    waitAndPay(n);

    /* unmapping the shared region off the process address space */
    if (shmemDettach (sh) == -1) {
        perror ("error on unmapping the shared region off the process address space");
        return EXIT_FAILURE;;
    }

    return EXIT_SUCCESS;
}

/**
 *  \brief client goes to restaurant
 *
 *  The client takes his time to get to restaurant.
 *
 *  \param id client id
 */
static void travel (int id)
{
    usleep((unsigned int) floor ((1000000 * random ()) / RAND_MAX + 1000));
}

/**
 *  \brief client eats
 *
 *  The client takes his time to eat a pleasant dinner.
 *
 *  \param id client id
 */
static void eat (int id)
{
    usleep((unsigned int) floor ((MAXEAT * random ()) / RAND_MAX + 1000));
}

/**
 *  \brief client waits until table is complete 
 *
 *  Client should udpate state, first and last clients should register their values in shared data,
 *  last client should, in addition, inform the others that the table is complete.
 *  Client must wait in this function until the table is complete.
 *  The internal state should be saved.
 *
 *  \param id client id
 *
 *  \return true if first client, false otherwise
 */
static bool waitFriends(int id)
{
    bool first = false;

    if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    if(sh->fSt.tableClients == 0)
    {
        sh->fSt.tableFirst = id;
        first = true;
        sh->fSt.tableClients++;
        sh->fSt.st.clientStat[id] = WAIT_FOR_FRIENDS;
        saveState(nFic, &sh->fSt);
    }
    else if(sh->fSt.tableClients == 19)
    {
        sh->fSt.tableLast = id;
        sh->fSt.tableClients++;
        sh->fSt.st.clientStat[id] = WAIT_FOR_FOOD;
        saveState(nFic, &sh->fSt);
    }
    else{
        sh->fSt.tableClients++;
        sh->fSt.st.clientStat[id] = WAIT_FOR_FRIENDS;
        saveState(nFic, &sh->fSt);
    }

    if (semUp (semgid, sh->mutex) == -1)                                                      /* exit critical region */
    { perror ("error on the up operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    while(sh->fSt.tableClients != 20){
        if (semDown (semgid, sh->friendsArrived) == -1)                                                     
        { perror ("error on the down operation for semaphore access (CT)");
            exit (EXIT_FAILURE);
        }
    }
    if (semUp (semgid, sh->friendsArrived) == -1)                                                    
    { perror ("error on the up operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }
    return first;
}

/**
 *  \brief first client orders food.
 *
 *  This function is used only by the first client.
 *  The first client should update its state, request food to the waiter and 
 *  wait for the waiter to receive the request.
 *  
 *  The internal state should be saved.
 *
 *  \param id client id
 */
static void orderFood (int id)
{
    if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    sh->fSt.st.clientStat[id] = FOOD_REQUEST; // esta a pedir comida
    sh->fSt.foodRequest = 1;
    saveState(nFic, &sh->fSt);

    if (semUp (semgid, sh->mutex) == -1)                                                      /* exit critical region */
    { perror ("error on the up operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */ 

    int i, count;
    while(1){
        count = 0;
        for(i = 0; i < TABLESIZE; i++){
            if(sh->fSt.st.clientStat[i] == WAIT_FOR_FOOD) // ainda nao estao todos com 4
                count++;
        }
        if(count == 19)
            break;
    }

    if (semUp (semgid, sh->waiterRequest) == -1)   // espera o waiter                                   
    { perror ("error on the up operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    if (semDown (semgid, sh->requestReceived) == -1) {  // fica á espera do waiter                                     
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    while(1){
        if(sh->fSt.foodOrder == 0) // assim que o chefe começar a cozinhar
            break;
    }

    sh->fSt.st.clientStat[id] = WAIT_FOR_FOOD;
    saveState(nFic, &sh->fSt);

}

/**
 *  \brief client waits for food.
 *
 *  The client updates its state, and waits until food arrives. 
 *  It should also update state after food arrives.
 *  The internal state should be saved twice.
 *
 *  \param id client id
 */
static void waitFood (int id)
{
    if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    if(id != sh->fSt.tableLast && id != sh->fSt.tableFirst){
        sh->fSt.st.clientStat[id] = WAIT_FOR_FOOD;
        saveState(nFic, &sh->fSt);
    }


    if (semUp (semgid, sh->mutex) == -1) {                                                  /* exit critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
        // espera que todos acabem de comer

    while(1){
        int count = 0;
        for(int i = 0; i < TABLESIZE; i++){
            if(sh->fSt.st.clientStat[i] == WAIT_FOR_FOOD)
                count++;
        }
        if(count == TABLESIZE)
            break;
    }

    if (semUp (semgid, sh->foodArrived) == -1) {                                  
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    while(1)
        if(sh->fSt.st.waiterStat == TAKE_TO_TABLE)
            break;

    if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }


    /* insert your code here */
    
    sh->fSt.st.clientStat[id] = EAT;
    saveState(nFic, &sh->fSt);

    if (semUp (semgid, sh->mutex) == -1) {                                                  /* exit critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }
}

/**
 *  \brief client waits for others to finish meal, last client to arrive pays the bill. 
 *
 *  The client updates state and waits for others to finish meal before leaving and update its state. 
 *  Last client to finish meal should inform others that everybody finished.
 *  Last client to arrive at table should pay the bill by contacting waiter and waiting for waiter to arrive.
 *  The internal state should be saved twice.
 *
 *  \param id client id
 */
static void waitAndPay (int id)
{
    bool last=false; // variavel que inidica que ja todos comeram

    if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    sh->fSt.tableFinishEat++;
    sh->fSt.st.clientStat[id] = WAIT_FOR_OTHERS;
    saveState(nFic, &sh->fSt);

    if (semUp (semgid, sh->mutex) == -1) {                                                  /* exit critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    while(sh->fSt.tableFinishEat != 20){
        if (semDown (semgid, sh->allFinished) == -1)                                                     
        { perror ("error on the down operation for semaphore access (CT)");
            exit (EXIT_FAILURE);
        }
    }
    last = true;
    if (semUp (semgid, sh->allFinished) == -1)                                                    
    { perror ("error on the up operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    if(last) { // se ja acabaram de comer;
        if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
           perror ("error on the down operation for semaphore access (CT)");
           exit (EXIT_FAILURE);
        }

        /* insert your code here */
        // update ao state para finished 
        if(id == sh->fSt.tableLast)
        {
            sh->fSt.st.clientStat[id] = WAIT_FOR_BILL;
            saveState(nFic, &sh->fSt);
        }
        else{
            sh->fSt.st.clientStat[id] = FINISHED;
            saveState(nFic, &sh->fSt);
        }
        

        if (semUp (semgid, sh->mutex) == -1) {                                                  /* exit critical region */
            perror ("error on the down operation for semaphore access (CT)");
            exit (EXIT_FAILURE);
        }

        /* insert your code here */
    while(1)
    {
        int count = 0;
        for(int i = 0; i < TABLESIZE; i++){
            if(sh->fSt.st.clientStat[i] == FINISHED)
                count++;
        }
        if(count == TABLESIZE-1){
            break;
        }
    }
    sh->fSt.paymentRequest = 1;
    if (semUp (semgid, sh->waiterRequest) == -1) {       // chama o waiter                                        
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
        }
    }
    while(1)
    {
        if(sh->fSt.st.waiterStat == RECEIVE_PAYMENT)
            break;
    }

    if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */

        if(id == sh->fSt.tableLast)
        {
            sh->fSt.st.clientStat[id] = FINISHED;
            saveState(nFic, &sh->fSt);
        }
        

    if (semUp (semgid, sh->mutex) == -1) {                                                  /* exit critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }   
}

