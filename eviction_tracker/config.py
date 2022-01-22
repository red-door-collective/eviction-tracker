import os
from flask_log_request_id import RequestIDLogFilter

LOGGING = {
    'version': 1,
    'disable_existing_loggers': True,
    'filters': {
        'request_id_filter': {
            '()': RequestIDLogFilter
        }
    },
    'formatters': {
        'standard': {
            'format': '%(asctime)s [%(levelname)s] %(name)s: %(message)s'
        },
        'json': {
            'class': 'pythonjsonlogger.jsonlogger.JsonFormatter',
            'format': '%(asctime)s %(name)s %(levelname)s %(request_id)s %(message)s'
        },
        'debug_json': {
            'class': 'pythonjsonlogger.jsonlogger.JsonFormatter',
            'format': '%(asctime)s %(name)s %(levelname)s %(message)s %(process)s %(processName)s %(pathname)s %(lineno)s'
        }
    },
    'handlers': {
        'file': {
            'class': 'logging.handlers.RotatingFileHandler',
            'level': 'DEBUG',
            'formatter': 'json',
            'filename': os.environ['LOG_FILE_PATH'],
            'filters': ['request_id_filter']
        }
    },
    'loggers': {
        '': {  # root logger
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': False
        },
        'gunicorn': {
            'level': 'INFO',
            'handlers': ['file'],
            'propagate': True,
        },
        'eviction_tracker.app': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': False
        },
        'eviction_tracker.commands': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': False
        },
        'eviction_tracker.jobs': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': False
        },
        'eviction_tracker.detainer_warrants.caselink.common': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': False
        },
        'eviction_tracker.detainer_warrants.caselink.warrants': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': False
        },
        'eviction_tracker.detainer_warrants.caselink.pleadings': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': False
        }
    }
}
