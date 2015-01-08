'''
This module is to be run on the home-sensing server,
to collect measurements from the home,

--------------------------
Written by Yonatan Vaizman
December 2014 - January 2015
'''

import sys;
import smtplib;
from email.mime.multipart import MIMEMultipart;
from email.mime.text import MIMEText;
from email.mime.image import MIMEImage;
import datetime;
import os;
import os.path;
import numpy;
import numpy.linalg;
import pickle;
import time;
import logging;
import json;
import socket;
import traceback;

import matplotlib;
matplotlib.use('Agg');
import matplotlib.pyplot as plt;

import pytz;


g__details_file = 'homes_details.conf';
g__email_file = 'email.conf';
g__data_superdir = 'home_data';

g__from_address = None;
g__password = None;
g__project_manager_email = 'yonatanv@gmail.com';

g__latest_failure_timestamp = 0;

def log_exception(ex,specific_message):
    logging.error(specific_message);
    logging.error(ex);
    logging.error(traceback.format_exc());
    return;


def read_email_details():
    global g__email_file, g__from_address, g__password;

    fid = file(g__email_file,'rb');
    for line in fid:
        line = line.strip();
        parts = line.split(':');
        if (parts[0] == 'email'):
            g__from_address = parts[1];
            pass; # end if...
        elif (parts[0] == 'password'):
            g__password = parts[1];
            pass; # end elif...
        else:
            logging.warning("[email] Unsupported parameter in email file: %s.",parts[0]);
        pass; # end for line...
    fid.close();

    if g__from_address == None:
        logging.error("[email] The detector's email address was not set.");
        exit();
        pass;
    if g__password == None:
        logging.error("[email] The detector's email password was not set.");
        exit();
        pass;

    return;

def read_homes_details():
    global g__details_file;

    homes = {};
    fid = file(g__details_file,'rb');
    homes = json.load(fid);
    fid.close();

    return homes;

def read_home_details(homeid):
    homes = read_homes_details();
    if homeid not in homes:
        return None;

    return homes[homeid];

def send_email_for_monitoring_trouble(homeid,home_data,timestamp,short_msg):
    global g__from_address, g__password, g__project_manager_email;

    to_address = g__project_manager_email;#home_data['email'];

    dateobj = datetime.datetime.fromtimestamp(timestamp);
    time_str = dateobj.strftime('%Y-%m-%d %H:%M')
    subject = 'Home: %s, Monitoring has stopped on: %s (%s)' % (homeid,time_str,short_msg);
    message_body = 'Hello!\nMonitoring has stopped for home: %s.\n\nPlease check what happened!\nHome sensing project.\n' % (homeid);

    msg_obj = MIMEMultipart();
    msg_obj['Subject'] = subject;
    msg_obj['From'] = g__from_address;
    msg_obj['To'] = to_address;
    body_content = MIMEText(message_body,'plain');
    msg_obj.attach(body_content);

    message_str = msg_obj.as_string();
    
    server = smtplib.SMTP("smtp.gmail.com",587);
    server.ehlo();
    server.starttls();
    server.login(g__from_address,g__password);
    server.sendmail(g__from_address,to_address,message_str);
    server.close();

    logging.info("[email] Sent email to report trouble.");

    return;


def get_records_file_for_day(time_in_the_day,homeid):
    data_dir = os.path.join(g__data_superdir,homeid);
    if not os.path.exists(data_dir):
        os.mkdir(data_dir);
        logging.info("[records file] Created directory: %s" % data_dir);
        pass;

    filename = '%s_%s.dat' % (homeid,time_in_the_day.strftime('%m-%d-%y'));
    records_file = os.path.join(data_dir,filename);

    return records_file;

def get_records_file_for_right_now(homeid):
    now = datetime.datetime.now();
    records_file = get_records_file_for_day(now,homeid);

    timestamp = int(time.mktime(now.timetuple()));

    return (records_file,timestamp,now);


def create_socket_to_home_sensor(ip_address,sensor_name):
    sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM);
    sock.settimeout(5.);
    port = 2000;
    try:
        sock.connect((ip_address,port));
        pass;
    except Exception as ex:
        log_exception(ex,"[socket] Failed connecting to home sensor.");
        return None;

    # Test the socket to see if it is the expected sensor:
    try:
        line = sock.recv(len(sensor_name));
        if line != sensor_name:
            logging.error("[socket] Socket presented the string '%s' instead of the sensor name '%s'." % (line,sensor_name));
            return None;
    except Exception as ex:
        log_exception(ex,"[socket] Failed to read a line from the created socket.");
        return None;

    sock.settimeout(1.);
    logging.info("[socket] Successfully created socket to the remote home-sensor: %s." % sensor_name);
    return sock;

def read_data_record_from_remote_sensor(sock):
    # Fetch a line, long enough to contain a whole record:
    fetch_len = 2048;
    try:
        raw_line = sock.recv(fetch_len);
        pass;
    except Exception as ex:
        log_exception(ex,"[socket] Failed reading line of length %d from sensor." % fetch_len);
        return None;

    # Extract a single record:
    try:
        # Try to capture a valid record within this long string:
        lines = raw_line.split('\n\rV');
        for line in lines:
            if len(line) == 41:
                break;
            pass;

        if len(line) != 41:
            raise Exception("Didn't find valid record in the long string");
        
        record_num = line[:8];
        line = line[8:];

        pass;
    except Exception as ex:
        log_exception(ex,"[socket] The line read from sensor is problematic for parsing.\nline: %s\n\n" % raw_line);
        return None;

    if len(line) < 31:
        logging.error("[socket] The line read from sensor is too short: %s" % line);
        return None;

    measurements = [];

    # Read the 8 chemical sensors:
    for ii in range(8):
        val_str = line[:3];
        line = line[3:];
        raw_val = float(int(val_str,16));
        val = sensor_val_from_raw(raw_val);
        measurements.append(val);
        pass; # end for ii in range(8)...

    # Add the temperature:
    temp_str = line[:4];
    line = line[4:];
    raw_temp = float(int(temp_str,16));
    temp = temp_val_from_raw(raw_temp);
    measurements.append(temp);

    # Add the humidity:
    hum_str = line[:3];
    raw_hum = float(int(hum_str,16));
    hum = humidity_val_from_raw(raw_hum);
    measurements.append(hum);

    return measurements;

def sensor_val_from_raw(raw_val):
    max_val = 3110;
    if raw_val > 0.:
        val = 10. * (max_val - raw_val) / raw_val;
        pass;
    else:
        val = 0.;
        pass;
    
    return val;

def temp_val_from_raw(raw_temp):
    temp = -40.1 + 0.01*raw_temp;
    return temp;

def humidity_val_from_raw(raw_hum):
    const = -2.0468;
    lin = 0.0367;
    square = -1.5955E-6;

    hum = const + lin*raw_hum + square*(raw_hum**2);
    return hum;

def monitor_home(homeid,home_data):

    # Connection to the home sensor:
    if 'ip_address' not in home_data:
        logging.error("[parameters] Missing home's ip_address field");
        return False;
    sock = create_socket_to_home_sensor(home_data['ip_address'],home_data['sensor_name']);
    if sock == None:
        logging.error("[socket] Failed to open a valid socket.");
        return False;

    # The file in which to save the data:
    (records_file,timestamp,now) = get_records_file_for_right_now(homeid);
    out_fid = file(records_file,'a');

    while True:
        # Check what is the appropriate file for right now:
        (now_file,timestamp,now) = get_records_file_for_right_now(homeid);
        if now_file != records_file:
            # Need to close the last day's file and start the new day's file:
            out_fid.close();
            records_file = now_file;
            out_fid = file(records_file,'a');
            logging.info("-"*20);
            logging.info("[records_file] Starting a new day records file: %s" % records_file);
            pass;

        # Get a single instance measurement:
        measurements = read_data_record_from_remote_sensor(sock);
        if measurements == None:
            out_fid.close();
            logging.error("[record] Failed to get record from sensor. timestamp: %s" % str(timestamp));
            return False;

        # Construct a new record line for the file:
        data_record_str = ','.join(map(str,measurements));
        time_of_day_in_hours = float(now.hour) + float(now.minute)/60. + float(now.second)/3600.;
        record_line = "%s,%s,%s\n" % (str(timestamp),str(time_of_day_in_hours),data_record_str);

        # Write to file:
        out_fid.write(record_line);

        # Sleep:
        time.sleep(1);
        
        pass; # end while...

    return False;

def monitor_multi_trials(homeid,home_data):
    global g__latest_failure_timestamp;

    forget_period_in_seconds = 10*60; # 10 minutes
    max_strikes = 100;
    strikes = 0;
    while True:
        start_monitoring = time.time();

        logging.info("#"*30);
        logging.info("### Home %s, current strike count: %d" % (homeid,strikes));

        try:
            working_fine = monitor_home(homeid,home_data);
            if working_fine:
                logging.info("!!! Something strange. Monitoring stopped with positive return.");
                pass;
            else:
                logging.error("[monitoring] Monitoring stopped with negative return.");
                pass;
            pass; # end try
        except Exception as ex:
            log_exception(ex,"[monitoring] Caught exception from monitoring:\n%s" % ex);
            pass;

        # If we are here the monitoring stopped. Need to alert the manager with an email:
        timestamp = time.time();
        send_email_for_monitoring_trouble(homeid,home_data,timestamp,'trial');

        # Update the strikes count:
        if (timestamp - g__latest_failure_timestamp > forget_period_in_seconds):
            # Then clear the strikes:
            strikes = 0;
            logging.info("[monitoring] Clearing strikes (forgive and forget time has passed since latest failure)");
            pass;
        else:
            strikes += 1;
            pass;

        # Update the latest failure timestamp:
        g__latest_failure_timestamp = timestamp;

        # Did we have too many strikes in a short time:
        if strikes >= max_strikes:
            break;
        
        # Wait a bit:
        time.sleep(0.5);
        pass; # end for trial...

    logging.error("[monitoring] Failed in too many trials in a short time. Stopping.");
    send_email_for_monitoring_trouble(homeid,home_data,timestamp,'stopped trying');

    return;

def main():
    global g__temp_file;

    if len(sys.argv) < 2:
        print "!!! Missing home-id argument.";
        exit();
        pass;

    homeid = sys.argv[1];
    home_data = read_home_details(homeid);
    if home_data == None:
        print "!!! Unrecognized home-id: ",homeid,".";
        exit();
        pass;

    log_file = os.path.join('logs','homeid_%s.log' % homeid);
    log_format = '%(asctime)s [%(levelname)s] %(message)s';
    date_format = '%Y-%B-%d %H:%M';
    logging.basicConfig(filename=log_file,level=logging.INFO,\
                        format=log_format,datefmt=date_format);

    monitoring_title = "=== Collecting data from home: %s ===" % homeid;
    logging.info("="*40);
    logging.info(" ");
    logging.info(monitoring_title);
    print monitoring_title;

    # Preparations:
    read_email_details();

    monitor_multi_trials(homeid,home_data);

    return;

if __name__ == "__main__":
    main();
