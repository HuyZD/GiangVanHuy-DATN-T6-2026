#include "PriorityTask.h"

static PriorityServiceCallback serviceCallback = nullptr;
static bool serviceRunning = false;

void PriorityTask_setServiceCallback(PriorityServiceCallback callback)
{
  serviceCallback = callback;
}

void PriorityTask_run()
{
  if (serviceCallback == nullptr || serviceRunning)
  {
    return;
  }

  serviceRunning = true;
  serviceCallback();
  serviceRunning = false;
}

void PriorityTask_delay(unsigned long durationMs)
{
  const unsigned long start = millis();
  while (millis() - start < durationMs)
  {
    PriorityTask_run();
    delay(1);
  }
}
