#!/usr/bin/env python
import sys
import argparse
import pycassa
import multiprocessing
import time

parser = argparse.ArgumentParser()
parser.add_argument('--host', default=u"127.0.0.1")
parser.add_argument('--port', default=9160, type=int)
parser.add_argument('--start_log_number', default=0, type=int)
parser.add_argument('--number_of_logs', default=0, type=int)
parser.add_argument('--multicommit_number', default=1, type=int)
parser.add_argument('--parallel_number', default=1, type=int)
group = parser.add_mutually_exclusive_group(required = True)
group.add_argument('--init', action='store_true', default=False)
group.add_argument('--write', action='store_true', default=False)
group.add_argument('--read', action='store_true', default=False)

args = parser.parse_args()
host = args.host
port = args.port
start_num = args.start_log_number
loop_num = args.number_of_logs
host_port = "%s:%d" % (host, port)
multicommit_num = args.multicommit_number

ks = 'TestKeyspace_2'
cf = 'Users'

if args.init == True:
        sm = pycassa.system_manager.SystemManager(host_port)
        try:
                sm.drop_keyspace(ks)
        except Exception, e:
                pass
        sm.create_keyspace(ks , pycassa.system_manager.SIMPLE_STRATEGY, {'replication_factor': '1'})
        sm.create_column_family(ks, cf, key_cache_size=42, gc_grace_seconds=1000)
        sys.exit(0)

if args.write == True:
        p=pycassa.pool.ConnectionPool(ks, [host_port])
        c=pycassa.ColumnFamily(p,cf, write_consistency_level=pycassa.ConsistencyLevel.ANY)

        print "write data from %d to %d" % (start_num, start_num + loop_num)
        b=c.batch(queue_size = multicommit_num)
        source_list = ["application", "system", "security"]

        start_time = time.time()
        for i in range(start_num, start_num + loop_num):
                clock = time.time()
                c.insert('%020d%020f"' % (i, clock) , {'timestamp':'%020f' % clock, 'source':source_list[i % 3], 'severity':"%d" % (i % 5), 'logeventid':'%d' % (i % 1000), 'value':'%d' % (i % 100)})
        b.send()
        end_time = time.time()

        print "wasted time: %f" %  (float(end_time) -  float(start_time))
        sys.exit(0)

if args.read == True:
        p=pycassa.pool.ConnectionPool(ks, [host_port])
        c=pycassa.ColumnFamily(p,cf)

        print "write data from %d to %d" % (start_num, start_num + loop_num)
        b=c.batch(queue_size = multicommit_num)
        source_list = ["application", "system", "security"]

        start_time = time.time()
        for i in range(start_num, start_num + loop_num):
                clock = time.time()
                c.insert('%020d%020f"' % (i, clock) , {'timestamp':'%020f' % clock, 'source':source_list[i % 3], 'severity':"%d" % (i % 5), 'logeventid':'%d' % (i % 1000), 'value':'%d' % (i % 100)})
        b.send()
        end_time = time.time()

        print "wasted time: %f" %  (float(end_time) -  float(start_time))
        sys.exit(0)

