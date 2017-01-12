#!/bin/bash

# Variables 

DB="namedatabase"
BKP_DIR="/directorytobackup/"
ACTUAL_DAY=$(date +'%Y%m%d')

# Log Variables

LOG_DIR="/tmp"
SESSION_LOG=${LOG_DIR}/$$.log
LOGFILE=${LOG_DIR}/restoredb.log
DATE=$(date +"%Y-%m-%d_%H:%M:%S")

# Function to Generate Log Session and File

LOG_GENERATE()

{
    DATA=$(date +"%Y-%m-%d %H:%M:%S")
    echo ${DATA} $1 | tee -ia ${SESSION_LOG}
}

# Function to Remove Database MySQL

drop_database() 

{
    LOG_GENERATE "REMOVE DATABASE "$DB" D-1"
        
        # REMOVE DATABASE WITH DEFAULT FILES TO LOGIN
        mysql --defaults-file=~/.my.cnf -e 'drop database "$DB" '

            case $? in

                0) LOG_GENERATE "Database "$DB" Removed Successfully";;
                *) LOG_GENERATE "Error Removing a Database "$DB" " ; 
                   cat ${SESSION_LOG} >> ${LOGFILE} ; 
                   rm -f ${SESSION_LOG}; 
                   exit 1;;
            
            esac
}


# Function to Create New Database MySQL

create_database() 

{
    LOG_GENERATE "CREATE NEW DATABASE  "$DB" D-1"

        # CREATE DATABASE WITH DEFAULT FILES TO LOGIN
        mysql --defaults-file=~/.my.cnf -e 'create database "$DB" '

            case $? in
            
               0) LOG_GENERATE "Database Created Successfully";;
               *) LOG_GENERATE "Error Creating a Database" ; 
                  cat ${SESSION_LOG} >> ${LOGFILE} ; 
                  rm -f ${SESSION_LOG} ; 
                  exit 1;;

            esac
}

# Function to Restore Database MySQL

restore_database()
{
    # Validate Mount Point
    if [ -d "$BKP_DIR$ACTUAL_DAY" ]; then 

        cd "$BKP_DIR""$ACTUAL_DAY"

            #Validate file to restore
            if [ -f "$DB".sql ]; then
                 cat "$DB".sql | mysql --defaults-file=~/.my.cnf "$DB"

                case "$?" in 
                    0) LOG_GENERATE "Restore Successfully Applied To The Database" ; 
                    cat  ${SESSION_LOG} >> ${LOGFILE} ; 
                    rm -f ${SESSION_LOG}; 
                    exit 0;;
                        
                    *) LOG_GENERATE "Restore Failed in Database" ; 
                    cat ${SESSION_LOG} >> ${LOGFILE} ; 
                    rm -f ${SESSION_LOG}; 
                    exit 1;;
                esac
         
        else    
            LOG_GENERATE " The file "$DB".sql Does Not Exist"
            cat ${SESSION_LOG} >> ${LOGFILE} ;
            rm -f ${SESSION_LOG}; 
            exit 1
            
        fi
   

    else

        LOG_GENERATE " The Mount Point "$BKP_DIR""$ACTUAL_DAY" Does Not Exist"
        cat ${SESSION_LOG} >> ${LOGFILE} ;
        rm -f ${SESSION_LOG}; 
        exit 1
            
    fi
   

}
#Validate Database created in server
DB_EXISTS=$(mysql --defaults-file=~/.my.cnf -e "SHOW DATABASES LIKE '"$DB"';" | grep "$DB" > /dev/null; echo "$?")

    if [ $DB_EXISTS -eq 0 ]; then

        drop_database
        create_database
        restore_database

    else
        create_database
        restore_database

fi

exit
