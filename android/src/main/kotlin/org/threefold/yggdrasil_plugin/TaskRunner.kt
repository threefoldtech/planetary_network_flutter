package org.jimber.tools

import android.R
import android.os.Handler
import android.os.Looper
import java.util.concurrent.Callable
import java.util.concurrent.Executor
import java.util.concurrent.Executors

typealias OnTaskComplete<R,T> = (R) -> (T)

class TaskRunner {
    private val executor: Executor = Executors.newSingleThreadExecutor() // change according to your requirements
    private val handler: Handler = Handler(Looper.getMainLooper())

    fun <R,T> executeAsync(callable: Callable<R>, callback: OnTaskComplete<R, T>){ // callBack: (input: String) -> String)
        executor.execute({
            val result = callable.call()
            handler.post({ callback(result) })
        })
    }

}

