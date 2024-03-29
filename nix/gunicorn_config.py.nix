{ listen, pythonpath }:
''
import multiprocessing
import os
from eviction_tracker.extensions import scheduler

workers = multiprocessing.cpu_count() * 2 + 1
bind = "${listen}"

proc_name = "eviction_tracker"
pythonpath = "${pythonpath}"
timeout = 120
statsd_host = "localhost:8125"
user = "eviction_tracker"
group = "within"
preload = True

def on_starting(server):
    flask_app = server.app.wsgi()
    run_jobs = os.environ.get('RUN_JOBS', 'true')
    print('will run jobs:', run_jobs)
    if run_jobs == 'true':
        print('Starting scheduler')
        scheduler.api_enabled = os.environ.get('SCHEDULER_API_ENABLED', 'False').lower() in ('true', '1', 't')
        scheduler.init_app(flask_app)
        scheduler.start()

        from eviction_tracker import jobs 
''