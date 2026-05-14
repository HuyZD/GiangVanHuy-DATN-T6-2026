#ifndef PRIORITY_TASK_H
#define PRIORITY_TASK_H

#include <Arduino.h>

typedef void (*PriorityServiceCallback)();

void PriorityTask_setServiceCallback(PriorityServiceCallback callback);
void PriorityTask_run();
void PriorityTask_delay(unsigned long durationMs);

#endif
