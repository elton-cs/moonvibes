import { useStore } from './store'

function App() {
  const { count, increment, decrement, reset } = useStore()

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl shadow-lg p-8 max-w-md w-full">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-800 mb-2">
            Welcome to Vite + React
          </h1>
          <p className="text-gray-600">
            A simple counter app with Zustand and Tailwind CSS
          </p>
        </div>
        
        <div className="text-center mb-8">
          <div className="text-6xl font-bold text-indigo-600 mb-4">
            {count}
          </div>
          <p className="text-gray-500">Current Count</p>
        </div>
        
        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <button
            onClick={decrement}
            className="px-6 py-3 bg-red-500 hover:bg-red-600 text-white font-semibold rounded-lg transition-colors duration-200"
          >
            Decrement
          </button>
          <button
            onClick={reset}
            className="px-6 py-3 bg-gray-500 hover:bg-gray-600 text-white font-semibold rounded-lg transition-colors duration-200"
          >
            Reset
          </button>
          <button
            onClick={increment}
            className="px-6 py-3 bg-green-500 hover:bg-green-600 text-white font-semibold rounded-lg transition-colors duration-200"
          >
            Increment
          </button>
        </div>
        
        <div className="mt-8 p-4 bg-gray-50 rounded-lg">
          <h2 className="text-lg font-semibold text-gray-800 mb-2">
            Tech Stack
          </h2>
          <ul className="text-sm text-gray-600 space-y-1">
            <li>⚡ Vite - Fast build tool</li>
            <li>⚛️ React - UI library</li>
            <li>🐻 Zustand - State management</li>
            <li>🎨 Tailwind CSS - Styling</li>
          </ul>
        </div>
      </div>
    </div>
  )
}

export default App
